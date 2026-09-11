\ Remove one vertical seam from a 24-bit uncompressed BMP.
\
\ Input:  samples/hopper.bmp
\ Output: output/hopper-carved.bmp
\
\ This is intentionally a compact test project for agent-driven interactive
\ Forth development.  It handles the common Windows BMP case used by the sample:
\ BM signature, BITMAPV4/V5-style header, 24 bits per pixel, no compression,
\ positive bottom-up height.

include? task-shmem.fth ../../fth/shmem.fth

variable inbuf
variable in-size
variable outbuf
variable out-size
variable pixel-offset
variable width
variable height
variable stride
variable out-width
variable out-stride
variable energy
variable prev-energy
variable seam

: u8 ( addr -- n ) c@ 255 and ;

: le16@ { addr -- n }
  addr u8
  addr 1+ u8 8 lshift or ;

: le32@ { addr -- n }
  addr u8
  addr 1 + u8 8 lshift or
  addr 2 + u8 16 lshift or
  addr 3 + u8 24 lshift or ;

: le16! { n addr -- }
  n 255 and addr c!
  n 8 rshift 255 and addr 1+ c! ;

: le32! { n addr -- }
  n 255 and addr c!
  n 8 rshift 255 and addr 1 + c!
  n 16 rshift 255 and addr 2 + c!
  n 24 rshift 255 and addr 3 + c! ;

: iabs ( n -- +n ) dup 0< if negate then ;
: imin ( a b -- min ) 2dup < if drop else nip then ;

: bmp-stride ( w -- stride ) 3 * 3 + 4 / 4 * ;

: >cell ( index base -- addr ) swap cells + ;

: energy@ ( x -- n ) energy @ >cell @ ;
: energy! ( n x -- ) energy @ >cell ! ;
: prev@ ( x -- n ) prev-energy @ >cell @ ;
: prev! ( n x -- ) prev-energy @ >cell ! ;
: seam@ ( y -- x ) seam @ >cell @ ;
: seam! ( x y -- ) seam @ >cell ! ;

: pixel-addr { x y -- addr }
  inbuf @ pixel-offset @ +
  height @ 1- y - stride @ * +
  x 3 * + ;

: out-pixel-addr { x y -- addr }
  outbuf @ pixel-offset @ +
  height @ 1- y - out-stride @ * +
  x 3 * + ;

: channel@ ( x y channel -- n ) pixel-addr + u8 ;

: clamp-x ( x -- x' )
  dup 0< if drop 0 exit then
  dup width @ >= if drop width @ 1- then ;

: clamp-y ( y -- y' )
  dup 0< if drop 0 exit then
  dup height @ >= if drop height @ 1- then ;

: diff-channel { x1 y1 x2 y2 c -- n }
  x1 clamp-x y1 clamp-y c channel@
  x2 clamp-x y2 clamp-y c channel@
  - iabs ;

: rgb-diff { x1 y1 x2 y2 -- n }
  x1 y1 x2 y2 0 diff-channel
  x1 y1 x2 y2 1 diff-channel +
  x1 y1 x2 y2 2 diff-channel + ;

: pixel-energy { x y -- n }
  x 1- y x 1+ y rgb-diff
  x y 1- x y 1+ rgb-diff + ;

: best-parent { x -- n }
  x prev@
  x 0> if x 1- prev@ imin then
  x width @ 1- < if x 1+ prev@ imin then ;

: compute-energy-row { y -- }
  width @ 0 do
    I y pixel-energy
    y 0> if I best-parent + then
    I energy!
  loop ;

: swap-energy-buffers ( -- )
  energy @ prev-energy @ energy ! prev-energy ! ;

: find-bottom-seam-start { | best best-x -- x }
  0 energy@ -> best
  0 -> best-x
  width @ 1 do
    I energy@ best <
    if I energy@ -> best I -> best-x then
  loop
  best-x ;

: choose-parent-x { x y | best best-x -- x' }
  x -> best-x
  x prev@ -> best
  x 0> if
    x 1- prev@ best < if x 1- -> best-x x 1- prev@ -> best then
  then
  x width @ 1- < if
    x 1+ prev@ best < if x 1+ -> best-x then
  then
  best-x ;

: trace-seam { | x -- }
  find-bottom-seam-start -> x
  x height @ 1- seam!
  height @ 1- 0 do
    x I choose-parent-x -> x
    x I 1- seam!
  -1 +loop ;

: copy-input-header ( -- )
  inbuf @ outbuf @ pixel-offset @ cmove ;

: copy-pixel { sx dx y -- }
  sx y pixel-addr dx y out-pixel-addr 3 cmove ;

: copy-row-without-seam { y | sx dx cut -- }
  y seam@ -> cut
  0 -> dx
  width @ 0 do
    I cut <> if
      I dx y copy-pixel
      dx 1+ -> dx
    then
  loop ;

: copy-pixels ( -- )
  height @ 0 do I copy-row-without-seam loop ;

: update-output-header ( -- )
  out-size @ outbuf @ 2 + le32!
  out-width @ outbuf @ 18 + le32!
  out-stride @ height @ * outbuf @ 34 + le32! ;

: validate-bmp ( -- )
  inbuf @ u8 66 <> abort" input is not a BMP"
  inbuf @ 1+ u8 77 <> abort" input is not a BMP"
  inbuf @ 28 + le16@ 24 <> abort" only 24-bit BMP is supported"
  inbuf @ 30 + le32@ 0 <> abort" compressed BMP is not supported"
  width @ 2 < abort" BMP is too narrow"
  height @ 1 < abort" BMP height must be positive" ;

: load-input { | fid got err bytes -- }
  S" samples/hopper.bmp" r/o bin open-file -> err -> fid
  err abort" could not open samples/hopper.bmp"
  fid file-size -> err -> bytes
  err abort" could not stat samples/hopper.bmp"
  bytes in-size !
  in-size @ allocate -> err inbuf !
  err abort" could not allocate input buffer"
  inbuf @ in-size @ fid read-file -> err -> got
  err abort" could not read samples/hopper.bmp"
  got in-size @ <> abort" short read"
  fid close-file throw ;

: parse-header ( -- )
  inbuf @ 10 + le32@ pixel-offset !
  inbuf @ 18 + le32@ width !
  inbuf @ 22 + le32@ height !
  width @ bmp-stride stride !
  width @ 1- out-width !
  out-width @ bmp-stride out-stride !
  pixel-offset @ out-stride @ height @ * + out-size ! ;

: allocate-work { | err -- }
  width @ cells allocate -> err energy !
  err abort" could not allocate energy row"
  width @ cells allocate -> err prev-energy !
  err abort" could not allocate previous energy row"
  height @ cells allocate -> err seam !
  err abort" could not allocate seam"
  out-size @ allocate -> err outbuf !
  err abort" could not allocate output buffer"
  outbuf @ out-size @ 0 fill ;

: compute-seam ( -- )
  height @ 0 do
    I compute-energy-row
    I height @ 1- < if swap-energy-buffers then
  loop
  trace-seam ;

: write-output { | fid err wrote -- }
  S" output/hopper-carved.bmp" w/o bin create-file -> err -> fid
  err abort" could not create output/hopper-carved.bmp"
  outbuf @ out-size @ fid write-file -> err
  err abort" could not write output/hopper-carved.bmp"
  fid close-file throw ;

: carve-one ( -- )
  load-input
  parse-header
  validate-bmp
  allocate-work
  compute-seam
  copy-input-header
  copy-pixels
  update-output-header
  write-output
  pe0? if
    ." carved " width @ . ." x" height @ .
    ." -> " out-width @ . ." x" height @ .
    ." : output/hopper-carved.bmp" cr
  then
  flushemit ;

carve-one
