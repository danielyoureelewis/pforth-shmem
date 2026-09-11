\ Verify raw GET from a plain dictionary VARIABLE after saved dictionary reload.

variable verify-variable-get-target
variable verify-variable-get-local

pe 0 = if 111 verify-variable-get-target ! else 999 verify-variable-get-target ! then
0 verify-variable-get-local !
barrier-all

pe 1 = if verify-variable-get-local verify-variable-get-target 1 0 get then
barrier-all

." variable-get pe=" pe . ." marker=" agent-save-marker . cr
pe 1 = if
  ." variable-get-result=" verify-variable-get-local @ . cr
then

barrier-all
flushemit
