\ Ask OpenSHMEM whether a dictionary VARIABLE has a remote pointer after reload.

variable verify-variable-ptr-target
variable verify-shared-ptr-target
shared-cell verify-shared-ptr-target !

barrier-all

." pe=" pe .
." variable=" verify-variable-ptr-target .
." variable-ptr-to-0=" verify-variable-ptr-target 0 ptr .
." shared=" verify-shared-ptr-target @ .
." shared-ptr-to-0=" verify-shared-ptr-target @ 0 ptr .
cr

barrier-all
flushemit
