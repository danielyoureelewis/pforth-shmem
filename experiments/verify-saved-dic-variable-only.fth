\ Verify defining and using a plain VARIABLE after saved dictionary reload.

variable verify-variable-only
pe 1000 + verify-variable-only !
." variable-only pe=" pe . ." value=" verify-variable-only @ . cr
barrier-all
flushemit
