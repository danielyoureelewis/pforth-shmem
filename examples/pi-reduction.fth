\ Parallel integer-grid estimate of pi.
\
\ This is a deliberately simple parallel benchmark.  Imagine the upper-right
\ quadrant of a GRID-SIZE by GRID-SIZE square.  Count how many integer grid
\ points fall inside the quarter circle x*x + y*y <= r*r.  Four times that
\ ratio approximates pi.
\
\ The parallel decomposition is by rows:
\   PE 0 owns the first band of rows.
\   PE 1 owns the next band of rows.
\   ...
\
\ Each PE only counts its local band.  Then all PEs call all-reduce-sum from
\ fth/shmem.fth.  That helper hides the low-level OpenSHMEM synchronization
\ buffer and gives us the total count on every PE.
\
\ Run from the repository root:
\   ./pforth-shmem -n 4 examples/pi-reduction.fth
\
\ Or run from build/unix:
\   oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/pi-reduction.fth

\ The friendly SHMEM words are loaded into the default dictionary, but this
\ include keeps the example runnable with older dictionaries too.
include? task-shmem.fth ../../fth/shmem.fth

\ Number of rows and columns in the quarter-square.
\ Keep this divisible by the number of PEs used for the simplest row split.
1000 constant GRID-SIZE

\ We print an integer fixed-point value instead of relying on floating point.
\ A result of 3145544 means approximately 3.145544.
1000000 constant SCALE

\ Each PE writes its own local count, then all-reduce-sum produces total-count.
variable local-count
variable total-count

\ This example uses the simplest possible block distribution, so GRID-SIZE
\ must divide evenly by PES.  A later teaching example could handle remainders.
: divisible? ( -- flag ) GRID-SIZE pes mod 0= ;

\ Number of rows owned by each PE.
: rows-per-pe ( -- n ) GRID-SIZE pes / ;

\ First row owned by this PE.  PE is zero-based.
: first-row ( -- row ) pe rows-per-pe * ;

\ Last row owned by this PE, inclusive.
: last-row ( -- row ) pe 1+ rows-per-pe * 1- ;

\ True if the point (row,col) lies inside the quarter circle.
\ Locals in pForth are declared between { and -- }.  They make examples much
\ clearer than stack juggling for two-dimensional code.
: inside-quarter-circle? { row col -- flag }
  row row * col col * + GRID-SIZE GRID-SIZE * <= ;

\ Count only this PE's row band.
\ In nested DO loops, I is the innermost loop index and J is the next outer
\ loop index.  Here J is the row and I is the column.
: count-local ( -- )
  0 local-count !
  last-row 1+ first-row do
    GRID-SIZE 0 do
      J I inside-quarter-circle? if 1 local-count +! then
    loop
  loop ;

\ Combine per-PE counts.  all-reduce-sum returns the sum on every PE, which is
\ a friendlier interface than passing pSync/work buffers to SUM-REDUCTION.
: accumulate-counts ( -- )
  local-count @ all-reduce-sum total-count ! ;

\ Convert the count ratio to fixed-point pi:
\   pi ~= 4 * points-inside / total-points
: scaled-pi ( -- n )
  total-count @ 4 * SCALE * GRID-SIZE GRID-SIZE * / ;

\ Only PE 0 prints.  Otherwise multi-PE output quickly becomes unreadable.
: print-result ( -- )
  pe0? if
    ." pi * " SCALE . ." ~= " scaled-pi . cr
    ." grid = " GRID-SIZE . ." x" GRID-SIZE . ." pes = " pes . cr
  then
  flushemit ;

\ Top-level driver.  The final word in the file is executed when the file is
\ included by pforth_standalone.
: run-pi ( -- )
  divisible? 0= if
    pe0? if ." GRID-SIZE must divide evenly by PES" cr then
    flushemit exit
  then
  count-local accumulate-counts print-result ;

run-pi
