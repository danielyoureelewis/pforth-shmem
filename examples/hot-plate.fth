\ Integer hot-plate/Jacobi stencil with row-block decomposition.
\
\ This is a classic stencil benchmark.  The top edge of a plate is held hot
\ and the other cells repeatedly become the average of their four neighbors.
\ Over many iterations heat diffuses from the top edge toward the center.
\
\ The decomposition is by rows.  Each PE computes a horizontal band of rows.
\ To keep the example easy to read, every PE stores a full copy of the grid.
\ After a PE computes its band into next-plate, it publishes those rows to all
\ PEs with put-cells.  After the barrier, every PE has the same complete plate
\ for the next iteration.
\
\ This is not the most memory-efficient stencil implementation.  A production
\ version would usually exchange only halo rows with neighboring PEs.  The
\ replicated-grid version is a better first teaching example because every
\ address and communication step is visible.
\
\ Run from the repository root:
\   ./pforth-shmem -n 4 examples/hot-plate.fth
\
\ Or run from build/unix:
\   oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/hot-plate.fth

include? task-shmem.fth ../../fth/shmem.fth

\ Grid shape and iteration count.  The temperatures are integers.  The top
\ boundary uses 10000 instead of 100 so integer division still leaves visible
\ heat at the center after a modest number of iterations.
16 constant GRID-ROWS
16 constant GRID-COLS
400 constant ITERATIONS
GRID-ROWS GRID-COLS * constant GRID-CELLS

\ shared-grid defines a word that maps ( row col -- addr ).
\ These arrays live in the pForth dictionary, which is symmetric in SHMEM mode.
GRID-ROWS GRID-COLS shared-grid plate
GRID-ROWS GRID-COLS shared-grid next-plate

\ This example uses equal row bands.  If GRID-ROWS is not divisible by PES, the
\ program prints an error instead of hiding a partial-row case in the example.
: divisible? ( -- flag ) GRID-ROWS pes mod 0= ;
: rows-per-pe ( -- n ) GRID-ROWS pes / ;
: first-row ( -- row ) pe rows-per-pe * ;
: last-row ( -- row ) pe 1+ rows-per-pe * 1- ;

\ Small accessors make the rest of the program read in grid coordinates.
\ plate and next-plate are defining words created by shared-grid.
: plate@ ( row col -- n ) plate @ ;
: plate! ( n row col -- ) plate ! ;
: next@ ( row col -- n ) next-plate @ ;
: next! ( n row col -- ) next-plate ! ;

\ Start both grids at zero.  We keep both grids initialized because the stencil
\ alternates between reading plate and writing next-plate.
: clear-grid ( -- )
  GRID-ROWS 0 do
    GRID-COLS 0 do
      0 J I plate!
      0 J I next!
    loop
  loop ;

\ The top edge is the heat source.  It is copied to both grids because boundary
\ cells are preserved every iteration.
: set-boundaries ( -- )
  GRID-COLS 0 do 10000 0 I plate! loop
  GRID-COLS 0 do 10000 0 I next! loop ;

\ PE 0 initializes the useful state, then BROADCAST copies it to all PEs.
\ The facade intentionally keeps raw BROADCAST available for whole-grid setup.
\ Stack for BROADCAST is:
\   target source nelems root pe-start log-stride pe-size psync -- 
: initialize ( -- )
  clear-grid set-boundaries
  0 0 plate 0 0 plate GRID-CELLS 0 0 0 pes shmem-sync broadcast
  0 0 next-plate 0 0 next-plate GRID-CELLS 0 0 0 pes shmem-sync broadcast ;

\ Boundary cells are fixed.  Interior cells are computed from neighbors.
: boundary-cell? { row col -- flag }
  row 0 = row GRID-ROWS 1- = or col 0 = or col GRID-COLS 1- = or ;

\ Integer Jacobi update: north + south + west + east, divided by 4.
: average-neighbors { row col -- n }
  row 1- col plate@
  row 1+ col plate@ +
  row col 1- plate@ +
  row col 1+ plate@ +
  4 / ;

\ Compute one cell in this PE's output grid.
: compute-cell { row col -- }
  row col boundary-cell? if
    row col plate@ row col next!
  else
    row col average-neighbors row col next!
  then ;

\ Compute this PE's band only.  J is the row, I is the column.
: compute-band ( -- )
  last-row 1+ first-row do
    GRID-COLS 0 do
      J I compute-cell
    loop
  loop ;

\ Publish one completed row from next-plate into plate on dest-pe.
\ put-cells has stack effect:
\   dest source cells pe --
\ Each PE calls this for every destination PE, so all PEs receive all computed
\ rows and end the iteration with the same full plate.
: publish-row { row dest-pe -- }
  row 0 plate row 0 next-plate GRID-COLS dest-pe put-cells ;

\ Publish every row this PE owns.  QUIET waits for outbound SHMEM operations
\ to complete; all-barrier keeps all PEs aligned before the next iteration.
: publish-band ( -- )
  pes 0 do
    last-row 1+ first-row do
      I J publish-row
    loop
  loop
  quiet all-barrier ;

\ One Jacobi iteration.
: step ( -- ) compute-band publish-band ;

\ A tiny result summary: if heat is moving, the center rises above zero.
: sample-center ( -- n ) GRID-ROWS 2 / GRID-COLS 2 / plate@ ;

\ Top-level driver.
: run-hot-plate ( -- )
  divisible? 0= if
    pe0? if ." GRID-ROWS must divide evenly by PES" cr then
    flushemit exit
  then
  initialize
  wtime
  ITERATIONS 0 do step loop
  wtime swap -
\ WTIME returns microseconds in this project.  Only PE 0 consumes and prints
\ the elapsed time; other PEs drop their local timing value.
  pe0? if
    ." hot plate " GRID-ROWS . ." x" GRID-COLS . ." iterations " ITERATIONS . cr
    ." pes = " pes . ." center = " sample-center . cr
    ." usec = " . cr
  else
    drop
  then
  flushemit ;

run-hot-plate
