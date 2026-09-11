\ Verify PUT to dictionary VARIABLE using a different dictionary VARIABLE source.

variable verify-variable-put-target2
variable verify-variable-put-source2

pe 0 = if 111 verify-variable-put-target2 ! else 222 verify-variable-put-target2 ! then
pe 1 = if 999 verify-variable-put-source2 ! then
barrier-all

pe 1 = if verify-variable-put-target2 verify-variable-put-source2 1 0 put then
barrier-all

." variable-put-different-source pe=" pe . ." marker=" agent-save-marker . cr
pe 0 = if
  ." variable-put-different-source-result=" verify-variable-put-target2 @ . cr
then

barrier-all
flushemit
