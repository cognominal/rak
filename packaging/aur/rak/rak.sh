#!/bin/sh
# rak — the installed launcher of the rak-git package. Same job as ./rak at
# the repo root: start the bundled rakudo with the rak frontend. With no
# arguments it starts irak, the REPL.
export RAKUDO_RAK_FRONTEND=1
export RAKU_RAK_MODE=1
exec /usr/lib/rak/bin/rakudo "$@"
