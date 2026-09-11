\ Verify barrier-all after loading a saved dictionary under multiple PEs.

." before-barrier pe=" pe . cr
flushemit
barrier-all
." after-barrier pe=" pe . ." pes=" pes . ." marker=" agent-save-marker . cr
flushemit
