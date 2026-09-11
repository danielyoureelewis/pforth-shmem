\ Verify raw GET with identical local dest and remote source addresses.

variable verify-variable-get-same-target

pe 0 = if 111 verify-variable-get-same-target ! else 999 verify-variable-get-same-target ! then
barrier-all

pe 1 = if verify-variable-get-same-target verify-variable-get-same-target 1 0 get then
barrier-all

." variable-get-same-address pe=" pe . ." marker=" agent-save-marker . cr
pe 1 = if
  ." variable-get-same-address-result=" verify-variable-get-same-target @ . cr
then

barrier-all
flushemit
