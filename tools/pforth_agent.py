#!/usr/bin/env python3
"""Agent-oriented driver for a live pforth-shmem interpreter.

The module keeps one interpreter process alive and sends snippets to it, so an
AI agent can probe stack effects and define words incrementally instead of
rewriting whole Forth files for every experiment.
"""

from __future__ import annotations

import argparse
import os
import selectors
import shlex
import subprocess
import sys
import time
from pathlib import Path


def compact_transcript(text: str) -> str:
    """Return the small part of a pForth transcript an agent usually needs."""

    kept: list[str] = []
    saw_stack = False
    saw_error = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if "[[PFORTH-AGENT-STACK" in line:
            kept.append(line[line.index("[[PFORTH-AGENT-STACK") :])
            saw_stack = True
        elif "THROW code =" in line or "Undefined word!" in line or "ABORT" in line:
            kept.append(line)
            saw_error = True
        elif " ? - unrecognized word!" in line:
            kept.append(line)
            saw_error = True

    if kept:
        return "\n".join(kept) + "\n"
    if saw_error:
        return "ERROR\n"
    if "[[PFORTH-AGENT-DONE" in text:
        return "OK\n"
    return text


class PForthAgentError(RuntimeError):
    """Raised when the interpreter session cannot complete a request."""


class PForthAgentSession:
    """Long-lived pforth-shmem evaluation session."""

    def __init__(
        self,
        *,
        root: str | Path | None = None,
        pes: int = 1,
        command: list[str] | None = None,
        timeout: float = 10.0,
    ) -> None:
        self.root = Path(root) if root is not None else Path(__file__).resolve().parents[1]
        self.pes = pes
        self.command = command or [str(self.root / "pforth-shmem"), "-n", str(pes)]
        self.timeout = timeout
        self.proc: subprocess.Popen[bytes] | None = None
        self.selector = selectors.DefaultSelector()
        self.buffer = ""

    def start(self) -> None:
        if self.proc is not None:
            return

        self.proc = subprocess.Popen(
            self.command,
            cwd=self.root,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
        )
        assert self.proc.stdout is not None
        os.set_blocking(self.proc.stdout.fileno(), False)
        self.selector.register(self.proc.stdout, selectors.EVENT_READ)

        agent_fth = self.root / "fth" / "agent.fth"
        self._write_line(f"include {agent_fth}")
        self._read_until_agent_markers("[[PFORTH-AGENT-READY", self.pes, self.timeout)

    def close(self) -> None:
        if self.proc is None:
            return
        if self.proc.poll() is None:
            try:
                self._write_line("bye")
                self.proc.wait(timeout=2)
            except (BrokenPipeError, subprocess.TimeoutExpired):
                self.proc.terminate()
        self.proc = None

    def eval(self, source: str, *, stack: bool = True, timeout: float | None = None) -> str:
        """Evaluate Forth source and return output through the completion marker."""

        self.start()
        marker = "[[PFORTH-AGENT-DONE"
        payload = source.rstrip()
        if payload:
            self._write_line(payload)
        if stack:
            self._write_line("agent-stack")
        self._write_line("agent-done")
        return self._read_until_agent_markers(marker, self.pes, timeout or self.timeout)

    def _write_line(self, line: str) -> None:
        if self.proc is None or self.proc.stdin is None or self.proc.poll() is not None:
            raise PForthAgentError("pforth process is not running")
        self.proc.stdin.write(line.encode("utf-8") + b"\n")
        self.proc.stdin.flush()

    def _read_until_agent_markers(self, marker: str, count: int, timeout: float) -> str:
        deadline = time.monotonic() + timeout
        while True:
            offset = 0
            end = -1
            found = 0
            while found < count:
                start = self.buffer.find(marker, offset)
                if start < 0:
                    break
                end = self.buffer.find("]]", start)
                if end >= 0:
                    end += 2
                    found += 1
                    offset = end
                else:
                    break
            if found >= count and end >= 0:
                chunk = self.buffer[:end]
                self.buffer = self.buffer[end:]
                return chunk

            if self.proc is not None and self.proc.poll() is not None:
                output = self._drain()
                raise PForthAgentError(
                    f"pforth exited with status {self.proc.returncode}\n{self.buffer}{output}"
                )
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(
                    f"timed out waiting for {count} occurrences of {marker}\n{self.buffer}"
                )
            events = self.selector.select(remaining)
            if not events:
                continue
            self.buffer += self._drain()

    def _drain(self) -> str:
        if self.proc is None or self.proc.stdout is None:
            return ""
        parts: list[bytes] = []
        while True:
            try:
                piece = self.proc.stdout.read(4096)
            except BlockingIOError:
                break
            if not piece:
                break
            parts.append(piece)
        return b"".join(parts).decode("utf-8", errors="replace")

    def __enter__(self) -> "PForthAgentSession":
        self.start()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:  # type: ignore[no-untyped-def]
        self.close()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate snippets in a live pforth-shmem interpreter."
    )
    parser.add_argument("--pes", type=int, default=1, help="number of OpenSHMEM PEs")
    parser.add_argument(
        "--timeout", type=float, default=10.0, help="seconds to wait for each result"
    )
    parser.add_argument(
        "--command",
        help="custom interpreter command, parsed like a shell command line",
    )
    parser.add_argument(
        "--eval",
        action="append",
        default=[],
        metavar="SOURCE",
        help="Forth source to evaluate; may be passed more than once",
    )
    parser.add_argument(
        "--file",
        action="append",
        default=[],
        metavar="PATH",
        help="Forth file to include in the live session",
    )
    parser.add_argument(
        "--no-stack",
        action="store_true",
        help="do not append agent-stack after each eval",
    )
    parser.add_argument(
        "--repl",
        action="store_true",
        help="read one Forth snippet per stdin line and print each result",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="print compact agent-facing observations instead of full transcripts",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    command = shlex.split(args.command) if args.command else None
    format_output = compact_transcript if args.compact else (lambda text: text)

    with PForthAgentSession(pes=args.pes, command=command, timeout=args.timeout) as session:
        for path in args.file:
            print(
                format_output(
                    session.eval(f"include {Path(path).resolve()}", stack=not args.no_stack)
                ),
                end="",
            )
        for source in args.eval:
            print(format_output(session.eval(source, stack=not args.no_stack)), end="")
        if args.repl:
            for line in sys.stdin:
                if line.strip().lower() == "bye":
                    break
                print(format_output(session.eval(line, stack=not args.no_stack)), end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
