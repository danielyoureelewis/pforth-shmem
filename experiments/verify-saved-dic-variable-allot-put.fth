\ Reproduce the older VARIABLE + ALLOT raw PUT pattern after saved reload.

variable verify-variable-allot-target 1 cells allot

pe 0 = if 111 verify-variable-allot-target ! else 999 verify-variable-allot-target ! then
barrier-all

pe 1 = if verify-variable-allot-target verify-variable-allot-target 1 0 put then
barrier-all

." variable-allot-put pe=" pe . ." marker=" agent-save-marker . cr
pe 0 = if
  ." variable-allot-put-result=" verify-variable-allot-target @ . cr
then

barrier-all
flushemit
