\ Verify that a saved dictionary still has working OpenSHMEM words.
\
\ Expected with -n 2:
\   - Both PEs can execute the saved marker word.
\   - PE 1 PUTs its value into PE 0's symmetric target.
\   - PE 0 prints put-result=999.

variable verify-target 1 cells allot

pe 0 = if 111 verify-target ! else 999 verify-target ! then
barrier-all

pe 1 = if verify-target verify-target 1 0 put then
barrier-all

." marker=" agent-save-marker . ." pe=" pe . ." pes=" pes . cr

pe 0 = if
  ." put-result=" verify-target @ . cr
then

barrier-all
flushemit
