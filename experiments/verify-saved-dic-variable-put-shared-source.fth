\ Verify PUT to dictionary VARIABLE using an explicit shared source buffer.

variable verify-variable-put-target
variable verify-shared-source
shared-cell verify-shared-source !

pe 0 = if 111 verify-variable-put-target ! else 999 verify-variable-put-target ! then
pe 1 = if 999 verify-shared-source @ ! then
barrier-all

pe 1 = if verify-variable-put-target verify-shared-source @ 1 0 put then
barrier-all

." variable-put-shared-source pe=" pe . ." marker=" agent-save-marker . cr
pe 0 = if
  ." variable-put-shared-source-result=" verify-variable-put-target @ . cr
then

barrier-all
flushemit
