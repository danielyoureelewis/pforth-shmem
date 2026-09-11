\ Agent-facing helpers for machine-readable pForth sessions.
\
\ Load this in an interactive interpreter when a host agent needs stable
\ markers around dynamic evaluations:
\
\   include /path/to/fth/agent.fth
\   1 2 + agent-stack
\
\ The words here are intentionally small and non-magical.  They do not catch
\ errors or hide normal pForth output; they only add parseable landmarks.

anew task-agent.fth

: agent-pe ( -- )
  ." pe=" pe . ;

: agent-ready ( -- )
  ." [[PFORTH-AGENT-READY " agent-pe ." ]]" cr flushemit ;

: agent-begin ( -- )
  ." [[PFORTH-AGENT-BEGIN " agent-pe ." ]]" cr flushemit ;

: agent-done ( -- )
  ." [[PFORTH-AGENT-DONE " agent-pe ." ]]" cr flushemit ;

: agent-stack { | d -- }
  depth -> d
  ." [[PFORTH-AGENT-STACK " agent-pe ." depth=" d . ." items="
  d 0 ?do
    d I - 1- pick .
  loop
  ." ]]" cr flushemit ;

: agent-pe-info ( -- )
  ." [[PFORTH-AGENT-PE " agent-pe ." pes=" pes . ." ]]" cr flushemit ;

agent-ready
