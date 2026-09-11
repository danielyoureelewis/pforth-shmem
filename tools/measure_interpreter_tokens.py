#!/usr/bin/env python3
"""Compare transcript sizes for three pForth agent workflows.

This is a pragmatic token experiment.  It measures bytes sent to pForth and
bytes that would be exposed back to the model, then estimates tokens as
bytes/4.  The same seam-carving workload is used in each mode.
"""

from __future__ import annotations

import json
import subprocess
import tempfile
from dataclasses import dataclass, asdict
from pathlib import Path

from pforth_agent import PForthAgentSession, compact_transcript


ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "samples" / "hopper.bmp"
OUT_BIG = ROOT / "output" / "measure-big-file.bmp"
OUT_REPL = ROOT / "output" / "measure-repl.bmp"


def repo_relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def seam_lines(output_path: Path) -> list[str]:
    out = str(output_path)
    sample = str(SAMPLE)
    return [
        "variable fid variable inbuf variable insize",
        "variable pixeloff variable width variable height variable stride",
        "variable outbuf variable outsize variable outwidth variable outstride",
        "variable energy variable prev variable parent variable seam",
        ": u8 c@ 255 and ;",
        ": le16@ { a -- n } a u8 a 1 + u8 8 lshift or ;",
        ": le32@ { a -- n } a u8 a 1 + u8 8 lshift or a 2 + u8 16 lshift or a 3 + u8 24 lshift or ;",
        ": le32! { n a -- } n 255 and a c! n 8 rshift 255 and a 1 + c! n 16 rshift 255 and a 2 + c! n 24 rshift 255 and a 3 + c! ;",
        ": bmp-stride 3 * 3 + 4 / 4 * ;",
        ": iabs dup 0< if negate then ;",
        ": clear-stack depth 0 ?do drop loop ;",
        f': open-sample S" {sample}" r/o bin open-file throw fid ! ;',
        ": size-sample fid @ file-size throw drop insize ! ;",
        ": alloc-input insize @ allocate throw inbuf ! ;",
        ': read-input inbuf @ insize @ fid @ read-file throw insize @ <> abort" short read" ;',
        ": close-input fid @ close-file throw ;",
        ": load-sample open-sample size-sample alloc-input read-input close-input ;",
        ": parse-header inbuf @ 10 + le32@ pixeloff ! inbuf @ 18 + le32@ width ! inbuf @ 22 + le32@ height ! width @ bmp-stride stride ! ;",
        ": pixel-addr { x y -- addr } inbuf @ pixeloff @ + height @ 1- y - stride @ * + x 3 * + ;",
        ": channel@ { x y c -- n } x y pixel-addr c + u8 ;",
        ": clamp-x dup 0< if drop 0 exit then dup width @ >= if drop width @ 1- then ;",
        ": clamp-y dup 0< if drop 0 exit then dup height @ >= if drop height @ 1- then ;",
        ": diff-channel { x1 y1 x2 y2 c -- n } x1 clamp-x y1 clamp-y c channel@ x2 clamp-x y2 clamp-y c channel@ - iabs ;",
        ": rgb-diff { x1 y1 x2 y2 -- n } x1 y1 x2 y2 0 diff-channel x1 y1 x2 y2 1 diff-channel + x1 y1 x2 y2 2 diff-channel + ;",
        ": pixel-energy { x y -- n } x 1- y x 1+ y rgb-diff x y 1- x y 1+ rgb-diff + ;",
        ": energy@ { x -- n } energy @ x cells + @ ;",
        ": energy! { n x -- } n energy @ x cells + ! ;",
        ": prev@ { x -- n } prev @ x cells + @ ;",
        ": idx { x y -- i } y width @ * x + ;",
        ": parent! { p x y -- } p parent @ x y idx cells + ! ;",
        ": parent@ { x y -- p } parent @ x y idx cells + @ ;",
        ": seam! { x y -- } x seam @ y cells + ! ;",
        ": seam@ { y -- x } seam @ y cells + @ ;",
        ": allocate-work width @ cells allocate throw energy ! width @ cells allocate throw prev ! width @ height @ * cells allocate throw parent ! height @ cells allocate throw seam ! ;",
        ": swap-energies energy @ prev @ energy ! prev ! ;",
        ": parent-choice { x | bx best -- bx best } x -> bx x prev@ -> best x 0> if x 1- prev@ best < if x 1- -> bx x 1- prev@ -> best then then x width @ 1- < if x 1+ prev@ best < if x 1+ -> bx x 1+ prev@ -> best then then bx best ;",
        ": compute-cell { x y | bx best e -- } x y pixel-energy -> e y 0> if x parent-choice -> best -> bx e best + -> e else x -> bx then bx x y parent! e x energy! ;",
        ": compute-row { y -- } width @ 0 do I y compute-cell loop ;",
        ": compute-all height @ 0 do I compute-row I height @ 1- < if swap-energies then loop ;",
        ": min-bottom { | bx best -- x } 0 -> bx 0 energy@ -> best width @ 1 do I energy@ best < if I -> bx I energy@ -> best then loop bx ;",
        ": trace-seam { | x y -- } min-bottom -> x height @ 1- -> y x y seam! begin y 0> while x y parent@ -> x y 1- -> y x y seam! repeat ;",
        ": setup-output width @ 1- outwidth ! outwidth @ bmp-stride outstride ! pixeloff @ outstride @ height @ * + outsize ! outsize @ allocate throw outbuf ! outbuf @ outsize @ 0 fill ;",
        ": out-pixel-addr { x y -- addr } outbuf @ pixeloff @ + height @ 1- y - outstride @ * + x 3 * + ;",
        ": copy-header inbuf @ outbuf @ pixeloff @ cmove ;",
        ": copy-pixel { sx dx y -- } sx y pixel-addr dx y out-pixel-addr 3 cmove ;",
        ": copy-row { y | dx cut -- } y seam@ -> cut 0 -> dx width @ 0 do I cut <> if I dx y copy-pixel dx 1+ -> dx then loop ;",
        ": copy-pixels height @ 0 do I copy-row loop ;",
        ": update-header outsize @ outbuf @ 2 + le32! outwidth @ outbuf @ 18 + le32! outstride @ height @ * outbuf @ 34 + le32! ;",
        f': write-output S" {out}" w/o bin create-file throw fid ! outbuf @ outsize @ fid @ write-file throw fid @ close-file throw ;',
        ": carve-output setup-output copy-header copy-pixels update-header write-output ;",
        "load-sample parse-header",
        "0 0 pixel-energy 64 64 pixel-energy 127 127 pixel-energy agent-stack",
        "clear-stack allocate-work compute-all trace-seam",
        "min-bottom 0 seam@ 64 seam@ 127 seam@ agent-stack",
        "clear-stack carve-output",
        "outwidth @ height @ outstride @ outsize @ agent-stack",
    ]


@dataclass
class Measurement:
    mode: str
    evals: int
    input_bytes: int
    visible_output_bytes: int
    total_bytes: int
    estimated_tokens: int
    output_file: str
    output_valid: bool


def approx_tokens(byte_count: int) -> int:
    return (byte_count + 3) // 4


def valid_bmp(path: Path, expected_width: int = 127) -> bool:
    data = path.read_bytes()
    return (
        data[:2] == b"BM"
        and int.from_bytes(data[18:22], "little", signed=True) == expected_width
        and int.from_bytes(data[22:26], "little", signed=True) == 128
        and int.from_bytes(data[28:30], "little") == 24
    )


def measure_big_file() -> Measurement:
    lines = seam_lines(OUT_BIG)
    source = "\n".join([f"include {ROOT / 'fth' / 'agent.fth'}"] + lines + ["bye"]) + "\n"
    with tempfile.NamedTemporaryFile("w", suffix=".fth", delete=False) as fh:
        path = Path(fh.name)
        fh.write(source)

    proc = subprocess.run(
        [str(ROOT / "pforth-shmem"), "-n", "1", str(path)],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    input_bytes = len(source.encode())
    output_bytes = len(proc.stdout.encode())
    total = input_bytes + output_bytes
    return Measurement(
        mode="one_big_file",
        evals=1,
        input_bytes=input_bytes,
        visible_output_bytes=output_bytes,
        total_bytes=total,
        estimated_tokens=approx_tokens(total),
        output_file=repo_relative(OUT_BIG),
        output_valid=proc.returncode == 0 and valid_bmp(OUT_BIG),
    )


def measure_interactive(*, compact: bool) -> Measurement:
    lines = seam_lines(OUT_REPL)
    input_bytes = 0
    output_bytes = 0
    with PForthAgentSession(root=ROOT, pes=1, timeout=20.0) as session:
        for line in lines:
            input_bytes += len((line + "\n").encode())
            full = session.eval(line, stack=False)
            visible = compact_transcript(full) if compact else full
            output_bytes += len(visible.encode())
    total = input_bytes + output_bytes
    return Measurement(
        mode="proposed_compact_interactive" if compact else "current_verbose_interactive",
        evals=len(lines),
        input_bytes=input_bytes,
        visible_output_bytes=output_bytes,
        total_bytes=total,
        estimated_tokens=approx_tokens(total),
        output_file=repo_relative(OUT_REPL),
        output_valid=valid_bmp(OUT_REPL),
    )


def main() -> int:
    ROOT.joinpath("output").mkdir(exist_ok=True)
    measurements = [
        measure_big_file(),
        measure_interactive(compact=False),
        measure_interactive(compact=True),
    ]
    report = {
        "method": "estimated_tokens = ceil((input_bytes + visible_output_bytes) / 4)",
        "measurements": [asdict(item) for item in measurements],
    }
    report_path = ROOT / "output" / "interpreter-token-measurement.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    print(f"saved {report_path}")
    return 0 if all(item.output_valid for item in measurements) else 1


if __name__ == "__main__":
    raise SystemExit(main())
