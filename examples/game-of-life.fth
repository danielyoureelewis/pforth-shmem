\ Conway's Game of Life with row-block decomposition.
\
\ Game of Life is a cellular automaton.  Each cell is either dead (0) or alive
\ (1).  On every step, the next state depends on the eight neighboring cells:
\   alive cell survives with 2 or 3 neighbors
\   dead cell becomes alive with exactly 3 neighbors
\   otherwise the next state is dead
\
\ Parallel strategy:
\   * split the rows evenly across PEs
\   * each PE computes only its own row band into next-grid
\   * each PE publishes its completed rows to every PE with put-cells
\   * after the barrier, every PE has the same complete grid
\
\ Like hot-plate.fth, this replicated-grid version favors clarity over memory
\ efficiency.  It is a good stepping stone before halo exchange examples.
\
\ Run from the repository root:
\   ./pforth-shmem -n 4 examples/game-of-life.fth
\
\ Or run from build/unix:
\   oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/game-of-life.fth

include? task-shmem.fth ../../fth/shmem.fth

\ Small grid so the final pattern can be printed directly.
16 constant GRID-ROWS
16 constant GRID-COLS
12 constant STEPS
GRID-ROWS GRID-COLS * constant GRID-CELLS

\ shared-grid defines words with stack effect ( row col -- addr ).
\ The two grids avoid in-place update bugs: read old state from grid, write new
\ state to next-grid, then publish next-grid rows back into grid.
GRID-ROWS GRID-COLS shared-grid grid
GRID-ROWS GRID-COLS shared-grid next-grid

\ Equal row bands, exactly like the hot plate example.
: divisible? ( -- flag ) GRID-ROWS pes mod 0= ;
: rows-per-pe ( -- n ) GRID-ROWS pes / ;
: first-row ( -- row ) pe rows-per-pe * ;
: last-row ( -- row ) pe 1+ rows-per-pe * 1- ;

\ Coordinate-based grid accessors.
: grid@ ( row col -- n ) grid @ ;
: grid! ( n row col -- ) grid ! ;
: next! ( n row col -- ) next-grid ! ;

\ Clear both buffers before seeding or receiving the broadcast.
: clear-grids ( -- )
  GRID-ROWS 0 do
    GRID-COLS 0 do
      0 J I grid!
      0 J I next!
    loop
  loop ;

\ A glider is the usual small Life pattern.  It should move down and right
\ while preserving five live cells.
: seed-glider ( -- )
  clear-grids
  1 1 2 grid!
  1 2 3 grid!
  1 3 1 grid!
  1 3 2 grid!
  1 3 3 grid! ;

\ Only PE 0 creates the initial pattern, then BROADCAST copies the full grid
\ to every PE.  This mirrors how real parallel programs often initialize input
\ once and distribute it.
: initialize ( -- )
  pe0? if seed-glider else clear-grids then
  0 0 grid 0 0 grid GRID-CELLS 0 0 0 pes shmem-sync broadcast ;

\ Return 0 outside the board.  This makes the board edges fixed-dead without
\ having to pad the grid with halo cells.
: live-at { row col -- n }
  row 0 < if 0 exit then
  col 0 < if 0 exit then
  row GRID-ROWS >= if 0 exit then
  col GRID-COLS >= if 0 exit then
  row col grid@ ;

\ Count the eight neighbors.  The local variable n is an accumulator; -> n
\ stores a new value in it.
: neighbors { row col | n -- n }
  0 -> n
  row 1- col 1- live-at n + -> n
  row 1- col live-at n + -> n
  row 1- col 1+ live-at n + -> n
  row col 1- live-at n + -> n
  row col 1+ live-at n + -> n
  row 1+ col 1- live-at n + -> n
  row 1+ col live-at n + -> n
  row 1+ col 1+ live-at n + -> n
  n ;

\ Apply the Life rule for one cell.
: next-cell { row col | alive n -- value }
  row col grid@ -> alive
  row col neighbors -> n
  alive if
    n 2 = n 3 = or if 1 else 0 then
  else
    n 3 = if 1 else 0 then
  then ;

\ Compute only this PE's row band.  Nested-loop convention: J=row, I=column.
: compute-band ( -- )
  last-row 1+ first-row do
    GRID-COLS 0 do
      J I next-cell J I next!
    loop
  loop ;

\ Publish one completed row from next-grid into grid on dest-pe.
: publish-row { row dest-pe -- }
  row 0 grid row 0 next-grid GRID-COLS dest-pe put-cells ;

\ Publish all rows owned by this PE to every PE, then wait for everyone.
: publish-band ( -- )
  pes 0 do
    last-row 1+ first-row do
      I J publish-row
    loop
  loop
  quiet all-barrier ;

\ One Life generation.
: step ( -- ) compute-band publish-band ;

\ Count live cells in the replicated final grid.  Because all PEs have the same
\ full grid after publish-band, PE 0 can compute and print this locally.
: count-live ( -- n )
  0
  GRID-ROWS 0 do
    GRID-COLS 0 do
      J I grid@ +
    loop
  loop ;

\ Print the final board.  # is live, . is dead.
: print-grid ( -- )
  GRID-ROWS 0 do
    GRID-COLS 0 do
      J I grid@ if ." #" else ." ." then
    loop
    cr
  loop ;

\ Top-level driver.
: run-life ( -- )
  divisible? 0= if
    pe0? if ." GRID-ROWS must divide evenly by PES" cr then
    flushemit exit
  then
  initialize
  STEPS 0 do step loop
  pe0? if
    ." game of life " GRID-ROWS . ." x" GRID-COLS . ." steps " STEPS . cr
    ." live cells = " count-live . cr
    print-grid
  then
  flushemit ;

run-life
