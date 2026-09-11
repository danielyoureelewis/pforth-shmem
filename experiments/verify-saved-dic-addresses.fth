\ Print dictionary and explicit shared addresses after saved dictionary load.

variable verify-address-target
variable verify-address-shared
shared-cell verify-address-shared !

." pe=" pe .
." codebase=" codebase .
." here=" here .
." variable=" verify-address-target .
." shared=" verify-address-shared @ .
cr
barrier-all
flushemit
