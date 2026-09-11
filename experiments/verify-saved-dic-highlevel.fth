\ Verify high-level shmem.fth helpers after saved dictionary load.

pe 1+ all-reduce-sum
." all-reduce-sum=" . ." pe=" pe . ." pes=" pes . cr
barrier-all
flushemit
