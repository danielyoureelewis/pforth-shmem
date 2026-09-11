# Legal Notice 
Permission to use, copy, modify, and/or distribute this
software for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


# About:
README for pforth-shmem - a Partitioned Global Address Space (PGAS) parallel FORTH by Daniel Y. Lewis. This is a modification of pForth by Phil Burk with Larry Polansky, David Rosenboom, Darren Gibbs, and Alexsej Saushev.

This is essentially a wrapper around the openSHMEM library for FORTH. pForth was chosen as a code base for this project because of it's straight forward implementation, and because it is written in ANSI C.

Last updated: 09/07/2026

# BUILD AND TEST:

WARNING: This project has only been tested on Debian with openMPI openSHMEM! If you run it with another openSHMEM or OS let me know!

1. Install an openSHMEM implementation for multi-PE runs. https://www.open-mpi.org/
2. Clone the repository. 
 ``` git clone https://github.com/danielyoureelewis/parallel-forth.git ```
3. Run ``` cd parallel-forth/build/unix ```
4. Run ``` ./build_and_test.sh ``` - You'll see tons of output. If OpenSHMEM tools are installed, the script builds with ```make SHMEM=1``` and runs with ```oshrun --mca memheap_base_max_segments 128 -n 2```. If ```oshcc``` or ```oshrun``` is not available, it builds the serial fallback and runs the same smoke tests with one PE.

You can also build explicitly:
```
make              # serial fallback for local development
make SHMEM=1      # OpenSHMEM build, expects oshcc and oshrun
```

The raw OpenSHMEM bindings remain available, but normal programs should start
with the higher-level words in ```fth/shmem.fth```. That layer provides common
Forth-style helpers including ```shared-cells```, ```shared-array```,
```shared-grid```, ```remote!```, ```remote@```, ```all-reduce-sum```,
```all-sum```, ```all-max```, ```all-min```, ```put-cells```, ```get-cells```,
```all-barrier```, ```all-sync```, and PE-0 output helpers like ```pe0?``` and
```pe0.```.

If everything worked with OpenSHMEM. The last 4 lines will be (the PE that reports their number first can change):
``` 
Including: test.fth
NUM PES: 2 
PE: 1 
PE: 0 
put test passed
get test passed
error test passed 
PForth V28-LE/64, built Apr 16 2021 21:22:31 (static)
PForth V28-LE/64, built Apr 16 2021 21:22:31 (static)


Including: test.fth
Including: test.fth

Testing Basics:
Testing with 2 pes.
PE: 0 present!
PE: 1 present!

Testing Collectives:

Testing Errors:
```

5. You can run in interactive mode with OpenSHMEM like so. ``` oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ```
The root-level wrapper also starts an interactive multi-PE interpreter when no
program path is provided:
```
./pforth-shmem -n 4
```
It can also load a saved pForth dictionary image:
```
./pforth-shmem -n 4 -d output/session.dic
./pforth-shmem -n 4 -d output/session.dic examples/raw-shmem.fth
```

Example programs live in ```examples/```. From the repository root, run them with:
```
./pforth-shmem -n 4 examples/pi-reduction.fth
./pforth-shmem -n 4 examples/hot-plate.fth
./pforth-shmem -n 4 examples/game-of-life.fth
```

Or from ```build/unix```, run them with the built standalone interpreter:
```
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/pi-reduction.fth
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/hot-plate.fth
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/game-of-life.fth
```

For AI-agent and tool-driven exploration, see
```docs/ai-agent-interpreter.md```.  The repository includes
```fth/agent.fth``` for parseable interpreter markers and
```tools/pforth_agent.py``` for keeping a live pForth process open while an
agent dynamically evaluates snippets and inspects the stack:

```
tools/pforth_agent.py --pes 1 --eval '1 2 +'
tools/pforth_agent.py --pes 2 --eval 'pe pes agent-stack'
```
   
Here is an example run:
```
PForth V28-LE/64, built Dec 20 2020 07:00:50 (static)
PForth V28-LE/64, built Dec 20 2020 07:00:50 (static)


hex
hex   ok
Stack<16> 
  ok
Stack<16> 
pe 0 = if DEADBEEF then pe 1 = if BEEFDEAD then ; 
pe 0 = if DEADBEEF then pe 1 = if BEEFDEAD then ;    ok
  ok
Stack<16> DEADBEEF 
Stack<16> BEEFDEAD 
variable target 1 cells allot ; 
variable target 1 cells allot ;    ok
Stack<16> BEEFDEAD 
  ok
Stack<16> DEADBEEF 
pe 0 = if 111 target ! then pe 1 = if 999 target ! then
pe 0 = if 111 target ! then pe 1 = if 999 target ! then   ok
Stack<16> BEEFDEAD 
  ok
Stack<16> DEADBEEF 
target @ . cr ; 
target @ . cr ; 999 
  ok
Stack<16> 
111 
  ok
Stack<16> 
pe 1 = if target target 1 0 put then ; 
pe 1 = if target target 1 0 put then ;    ok
Stack<16> 
  ok
Stack<16> BEEFDEAD 
target @ . cr ; 
target @ . cr ;  999 
999 
  ok
Stack<16> 
  ok
Stack<16> 
```

# TODO:
DONE: In interactive mode the stack should print the PE to which it belongs

DONE: Test standard floating point ops. The standard pForth test target runs ```t_floats.fth```. Multi-PE ```FSUM-REDUCTION``` still needs focused follow-up; ```build/unix/cpi.fth``` currently aborts under this OpenSHMEM runtime.

DONE: Add more SHMEM functions - collectives etc. The dictionary now exposes 32-bit data movement and collectives (`PUT32`, `GET32`, `BROADCAST32`, `COLLECT32`, `FCOLLECT32`, `ALL-TO-ALL32`), memory-ordering and address helpers (`FENCE`, `PTR`), locks (`SET-LOCK`, `CLEAR-LOCK`, `TEST-LOCK`), and cell-sized atomics (`ATOMIC-FETCH`, `ATOMIC-SET`, `ATOMIC-ADD`, `ATOMIC-FETCH-ADD`, `ATOMIC-SWAP`, `ATOMIC-COMPARE-SWAP`, `ATOMIC-INC`, `ATOMIC-FETCH-INC`).

Look for a way to integrate MPI functions

DONE: Segregate memory so that all allocations do not need to be symmetric. Ordinary pForth allocation now uses process-local memory; explicit ```SHARED```/```SHARED-FREE``` and the task/dictionary allocations that still participate in OpenSHMEM communication remain symmetric.
