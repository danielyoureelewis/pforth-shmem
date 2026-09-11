\ Verify raw PUT to a plain dictionary VARIABLE after saved dictionary reload.

variable verify-variable-target

pe 0 = if 111 verify-variable-target ! else 999 verify-variable-target ! then
barrier-all

pe 1 = if verify-variable-target verify-variable-target 1 0 put then
barrier-all

." variable-put pe=" pe . ." marker=" agent-save-marker . cr
pe 0 = if
  ." variable-put-result=" verify-variable-target @ . cr
then

barrier-all
flushemit
