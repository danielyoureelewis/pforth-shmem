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

Last updated: 12/20/2020

# BUILD AND TEST:

WARNING: This project has only been tested on Debian with openMPI openSHMEM! If you run it with another openSHMEM or OS let me know!

1. Install an openSHMEM implementation. https://www.open-mpi.org/
2. Clone the repository. 
 ``` git clone https://github.com/danielyoureelewis/parallel-forth.git ```
3. Run ``` cd parallel-forth/build/unix ```
4. Run ``` ./build_and_test.sh ``` - You'll see tons of output. If everything worked. The last 4 lines will be (the PE that reports their number first can change):
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

5. You can run in interactive mode like so. ``` oshrun -n 4 ./pforth_standalone ```
   
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
In interactive mode the stack should print the PE to which it belongs

Test floating point ops

Add more SHMEM functions - collectives etc

Look for a way to integrate MPI functions

Segregate memory so that all allocations do not need to be symmetric.
