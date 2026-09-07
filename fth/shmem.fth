\ Higher-level OpenSHMEM words for pForth.
\ The C glue still exposes low-level SHMEM words directly. This file provides
\ Forth-shaped helpers for normal programs.

anew task-shmem.fth

8 constant SHMEM-SYNC-CELLS
64 constant SHMEM-WORK-CELLS

variable shmem-value
variable shmem-total
variable shmem-sync SHMEM-SYNC-CELLS cells allot
variable shmem-work SHMEM-WORK-CELLS cells allot

: shmem-init-sync ( -- )
  SHMEM-SYNC-CELLS 0 do 0 shmem-sync I cells + ! loop ;

shmem-init-sync

: pe0? ( -- flag ) pe 0 = ;
: pe0. ( n -- ) pe0? if . else drop then ;
: pe0-cr ( -- ) pe0? if cr then ;
: pe0-type ( c-addr u -- ) pe0? if type else 2drop then ;

: all-barrier ( -- ) barrier-all ;
: all-sync ( -- ) sync ;

: shared-cells ( n -- addr ) cells shared ;
: shared-cell ( -- addr ) 1 shared-cells ;

: shared-array ( n <name> -- ) ( index -- addr )
  create cells allot
  does> swap cells + ;

: shared-grid ( rows cols <name> -- ) ( row col -- addr )
  create dup , over , * cells allot
  does> { row col grid -- addr }
    row grid @ * col + cells grid 2 cells + + ;

: remote! ( value addr pe -- )
  >r >r shmem-value ! r> shmem-value 1 r> put ;

: remote@ ( addr pe -- value )
  >r shmem-value swap 1 r> get shmem-value @ ;

: p! ( value addr pe -- ) remote! ;
: p@ ( addr pe -- value ) remote@ ;

: atomic+! ( value addr pe -- )
  >r swap r> atomic-add ;

: put-cells ( dest source cells pe -- ) put ;
: get-cells ( dest source cells pe -- ) get ;

: all-reduce-sum ( value -- sum )
  pe0? if 0 shmem-total ! then
  all-barrier
  shmem-total swap 0 atomic-add
  fence all-barrier
  shmem-total shmem-total 1 0 0 0 pes shmem-sync broadcast
  shmem-total @ ;

: all-sum ( addr -- )
  dup @ all-reduce-sum swap ! ;

: all-reduce-max ( value -- max )
  shmem-value !
  shmem-value shmem-value 1 0 0 pes shmem-work shmem-sync max-reduction
  shmem-value @ ;

: all-reduce-min ( value -- min )
  shmem-value !
  shmem-value shmem-value 1 0 0 pes shmem-work shmem-sync min-reduction
  shmem-value @ ;

: all-max ( addr -- )
  dup @ all-reduce-max swap ! ;

: all-min ( addr -- )
  dup @ all-reduce-min swap ! ;
