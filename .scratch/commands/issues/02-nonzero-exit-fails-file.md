# 02: Fail a `.rak` file on a non-zero exit status

Status: ready-for-agent

**Spec:** `rak-plans/features/commands.md`, Exit status: a non-zero exit status fails a
`.rak` file, like `run` in sink context. irak only shows a dimmed `exit N` (done).

**Today:** `RAK-RUN-COMMAND` returns a `Proc` (or the captured `Str`) and nothing throws,
so `false; say 1` in a `.rak` file prints `1` and exits 0.

**Open point:** whether a captured command `(false)` should fail too, or only a sunk one.

**Done when:** a sunk failing command stops a `.rak` file with the command's exit code,
irak is unchanged, with a test in `t/15-commands/rak/`.
