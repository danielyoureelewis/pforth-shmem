\ Minimal low-level SHMEM example.
\
\ Most programs should prefer the friendlier words in fth/shmem.fth.  This
\ file intentionally shows the raw bindings so users can see what the facade is
\ hiding.
\
\ Goal:
\   PE 0 starts with target = 111.
\   PE 1 starts with target = 999.
\   PE 1 writes its target value into PE 0's target variable using PUT.
\   PE 0 prints 999 after the transfer.
\
\ Run from the repository root:
\   ./pforth-shmem -n 2 examples/raw-shmem.fth
\
\ Or run from build/unix:
\   oshrun --mca memheap_base_max_segments 128 -n 2 ./pforth_standalone ../../examples/raw-shmem.fth

\ This target variable is in the Forth dictionary.  In SHMEM mode the
\ dictionary is symmetric, so every PE has a target at a corresponding address.
variable target 1 cells allot

\ pSync is the synchronization work area required by some low-level collectives.
\ This particular file only uses barrier-all and put, but keeping pSync here
\ makes the raw example look like older low-level examples in the project.
variable pSync pes cells allot

\ Give each PE a different local value.
pe 0 = if 111 target ! else 999 target ! then

\ Make sure both PEs have initialized target before the PUT.
barrier-all

\ Raw PUT stack effect:
\   dest source nelems pe --
\
\ On PE 1, both dest and source are named target.  In OpenSHMEM, the source is
\ local PE 1 memory and the destination is the corresponding symmetric address
\ on PE 0.  nelems is in pForth cells because this project's wrapper defines
\ PUT as cell-oriented.
pe 1 = if target target 1 0 put then

\ Wait until PE 1 has issued its PUT before PE 0 reads and prints.
barrier-all

\ Only PE 0 prints the value that PE 1 wrote.
pe 0 = if
  ." raw PUT result on PE 0 = " target @ . cr
then
flushemit
