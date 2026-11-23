# 01: Make `$?` per routine

Status: ready-for-agent

**Spec:** `rak-plans/features/commands.md`, Exit status: `$?` holds the last exit status
per routine, like `$!`.

**Today:** `$?` reads `RAK-STATUS()`, a single process-global variable in
`src/core.c/Rakudo/Internals/RakFormat.rakumod`, so a command run inside a routine
changes the caller's `$?`.

**Done when:** a command run in a routine leaves the caller's `$?` unchanged, with a test
in `t/15-commands/rak/`.
