# AI agent interpreter access

`pforth-shmem` is a good fit for live agent interaction because Forth words can
be defined, executed, inspected, and revised in very small loops.  This
repository includes a thin protocol layer for that workflow:

- `fth/agent.fth` adds machine-readable readiness, PE, completion, and stack
  markers.
- `tools/pforth_agent.py` keeps one interpreter process alive and evaluates
  snippets inside that process.

## CLI use

From the repository root:

```sh
tools/pforth_agent.py --pes 1 --eval '1 2 +'
tools/pforth_agent.py --pes 2 --eval 'pe pes agent-stack'
tools/pforth_agent.py --pes 4 --file examples/pi-reduction.fth --no-stack
```

For line-oriented interactive use:

```sh
tools/pforth_agent.py --pes 1 --repl
```

Each evaluated snippet is followed by `agent-stack` unless `--no-stack` is
passed.  In multi-PE sessions, each PE emits its own protocol markers and the
driver waits for one completion marker per PE.  The stack marker is
intentionally parseable:

```text
[[PFORTH-AGENT-STACK pe=0 depth=1 items=3 ]]
[[PFORTH-AGENT-DONE pe=0 ]]
```

## Python use

```python
from tools.pforth_agent import PForthAgentSession

with PForthAgentSession(pes=1) as forth:
    print(forth.eval(": square dup * ;"))
    print(forth.eval("7 square"))
```

Definitions persist for the lifetime of the session, which lets an agent build
up vocabulary incrementally before copying the proven words into a `.fth` file.

## Protocol words

Load the protocol directly inside any pForth session:

```forth
include /absolute/path/to/fth/agent.fth
```

Available words:

- `agent-ready` prints a readiness marker.
- `agent-begin` prints a begin marker.
- `agent-done` prints a done marker.
- `agent-stack` prints PE, stack depth, and stack items without consuming them.
- `agent-pe-info` prints PE and total PE count.

The protocol does not suppress normal interpreter output or catch pForth
errors.  If a snippet aborts before the completion marker is emitted, the host
driver times out and returns the transcript collected so far.

## Recommended agent loop

1. Start one `PForthAgentSession`.
2. Evaluate one small word or stack experiment at a time.
3. Inspect `agent-stack` after each step.
4. Use `see`, `words`, and `words.like` for vocabulary discovery.
5. Move stable definitions into a checked-in `.fth` file.
6. Run the full file with `./pforth-shmem -n N path/to/file.fth`.

This keeps the agent in Forth's natural feedback loop while still ending with a
clean, repeatable program file.

## Dictionary checkpoints

pForth can save the current dictionary image:

```forth
c" output/session.dic" save-forth
```

Reload it through the repository wrapper:

```sh
./pforth-shmem -n 2 -d output/session.dic experiments/verify-saved-dic-loadonly.fth
```

Dictionary checkpoints are useful for fast recovery of live-defined words.  A
source journal is still recommended because comments do not survive as useful
dictionary metadata.
