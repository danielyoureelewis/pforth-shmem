\ Verify PUT from explicitly allocated symmetric memory after saved dictionary load.

variable verify-target
shared-cell verify-target !

pe 0 = if 111 verify-target @ ! else 999 verify-target @ ! then
barrier-all

pe 1 = if verify-target @ verify-target @ 1 0 put then
barrier-all

." shared-put pe=" pe . ." marker=" agent-save-marker . cr
pe 0 = if
  ." shared-put-result=" verify-target @ @ . cr
then

barrier-all
flushemit
