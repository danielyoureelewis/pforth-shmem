: debug false ; 
( vars used in testing )
variable target 1 cells allot ;
variable dest 1 cells allot ;
variable lock 1 cells allot ;
variable atomic-value 1 cells allot ;

( helper words )
: print-0-stack debug true = pe 0 = and if .S then ; 

: print-target debug if pe . target @ . cr then ;

( test words )
: test-pes pe 0 = if
             ." Testing with " pes .
             ." pes."  cr
           then
           flushemit
           barrier-all ;

: test-pe ." PE: " pe . ." present!" cr flushemit ;

: test-put pe 0 = if
             111 target !
           then
           pe 1 = if
             999 target !
           then
           print-target
           barrier-all
           pe 1 = if
             target target 1 0 PUT
           then
           pes 1 = pe 0 = and if
             target target 1 0 PUT
           then
           barrier-all
           pe 0 = pes 1 > and 999 target @ = invert and if
             ." put test failed" cr
           then
           pe 0 = pes 1 = and 111 target @ = invert and if
             ." put test failed" cr
           then
           flushemit
           print-target ;

: test-get pe 0 = if
             111 target !
           then
           pe 1 = if
             999 target !
           then
           print-target
           barrier-all
           pe 0 = if
             pes 1 > if
               target target 1 1 GET
             else
               target target 1 0 GET
             then
           then
           barrier-all
           pe 0 = pes 1 > and 999 target @ = invert and if
             ." get test failed" cr
           then
           pe 0 = pes 1 = and 111 target @ = invert and if
             ." get test failed" cr
           then
           flushemit
           print-target ;

: test-shared cell shared dup 0= if
                ." shared alloc failed" cr
              else
                123 over !
                shared-free
              then
              flushemit ;

: test-ptr target pe ptr 0= if
             ." ptr test failed" cr
           then
           flushemit ;

: test-locks pe 0 = if
               0 lock !
             then
             barrier-all
             pe 0 = if
               lock test-lock 0= invert if
                 ." test-lock failed" cr
               then
               lock clear-lock
               lock set-lock
               lock clear-lock
             then
             barrier-all
             flushemit ;

: test-atomics pe 0 = if
                 0 atomic-value !
                 atomic-value 7 0 atomic-fetch-add 0 = invert if
                   ." atomic fetch-add failed" cr
                 then
                 atomic-value 0 atomic-fetch 7 = invert if
                   ." atomic fetch failed" cr
                 then
                 atomic-value 11 0 atomic-swap 7 = invert if
                   ." atomic swap failed" cr
                 then
                 atomic-value 11 13 0 atomic-compare-swap 11 = invert if
                   ." atomic compare-swap failed" cr
                 then
                 atomic-value 0 atomic-fetch-inc 13 = invert if
                   ." atomic fetch-inc failed" cr
                 then
                 atomic-value 0 atomic-inc
                 atomic-value 0 atomic-fetch 15 = invert if
                   ." atomic inc failed" cr
                 then
                 atomic-value 20 0 atomic-set
                 atomic-value 0 atomic-fetch 20 = invert if
                   ." atomic set failed" cr
                 then
                 0 atomic-value !
               then
               barrier-all
               atomic-value 1 0 atomic-add
               fence
               barrier-all
               pe 0 = pes atomic-value @ = invert and if
                 ." atomic add failed" cr
               then
               flushemit ;

variable pSync pes cells allot ;
: test-broadcast pe 0 = if
                   111 target !
                 else
                   999 target !
                 then
                 barrier-all
                 print-target
                 target target 1 0 0 0 pes pSync broadcast
                 pe 1 = 111 target @ = invert and if
                   ." broadcast test failed" cr
                 then
                 flushemit
                 print-target ; 
                   
: test-error false = invert pe 0 = and if
               ." error test passed" cr
             then
             flushemit ;

variable collection pes cells allot ;  
: test-collect pe target !
               collection target 1 0 0 pes pSync collect
               pes 0 do
                 collection I cells + @ I = invert if
                   pe ." collect failed" cr leave
                 then
               loop ;

variable work 2 cells allot ;
: test-and-reduction 1 target !
                     target target 1 0 0 pes work pSync and-reduction
                     1 target @ = invert if ." and reduction failed" then
                     pe target ! 
                     target target 1 0 0 pes work pSync and-reduction
                     0 target @ = invert if ." and reduction failed" then ;

: test-max-reduction pe target ! 
                     target target 1 0 0 pes work pSync max-reduction
                     pes 1 - target @ = invert if ." max reduction failed" then ;

: test-min-reduction pe target ! 
                     target target 1 0 0 pes work pSync min-reduction
                     0 target @ = invert if ." min reduction failed" then ;

: test-sum-reduction 1 target ! 
                     target target 1 0 0 pes work pSync sum-reduction
                     pes target @ = invert if ." sum reduction failed" cr then ;

: test-prod-reduction pes target ! 
                     target target 1 0 0 pes work pSync prod-reduction
                     pes pes * target @ = invert if ." prod reduction failed" cr then ;

: test-or-reduction pe 0 = if 10000000 target ! else 1 target ! then  
                     target target 1 0 0 pes work pSync or-reduction
                     pes 1 = if
                       10000000
                     else
                       10000001
                     then target @ = invert if ." or reduction failed" cr then ;

: test-xor-reduction pe 0 = if 10000001 target ! else 1 target ! then  
                     target target 1 0 0 pes work pSync xor-reduction
                     pes 1 = if
                       10000001
                     else
                       10000000
                     then target @ = invert if ." xor reduction failed" cr then ;

variable exchange pes cells allot ;

: test-all-to-all pe target ! 
                pes 0 do
                  pe exchange I cells + !
                  0 collection I cells + !
                loop
                collection exchange 1 0 0 pes pSync all-to-all 
                pes 0 do
                  collection I cells + @ I = invert if
                    ." alltoall failed" cr leave
                  then
                loop ;
                
0 pe = if cr ." Testing Basics:" cr flushemit then ; 
barrier-all ; 
test-pes
print-0-stack
test-pe
print-0-stack
test-put
print-0-stack
test-get
print-0-stack
test-shared
print-0-stack
test-ptr
print-0-stack
test-locks
print-0-stack
test-atomics
print-0-stack
barrier-all ; 
0 pe = if cr ." Testing Collectives:" cr flushemit then ; 
barrier-all ; 
test-broadcast
print-0-stack
barrier-all ; 
test-collect
print-0-stack ;
barrier-all ; 
test-and-reduction 
test-max-reduction
test-min-reduction
test-prod-reduction
test-or-reduction
test-xor-reduction
test-all-to-all 
0 pe = if cr ." Testing Errors:" cr flushemit then ; 
barrier-all ;
pe test-error
