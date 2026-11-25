# irak: recalling submissions

Status: WIP — tested by `t/02-rakudo/rak/020-irak-bang.t`, except TAB.

## Spec

- `!n` ENTER re-runs the source of [submission](../../GLOSSARY.md#irak-submission) n.
- `!!n` sets `$_` to the value of submission n.
- Submissions are stored per session, capped at 1000.
- ↑/↓ history is kept in `$XDG_STATE_HOME/rak/history` (default
  `~/.local/state/rak/history`), see [the startup file](startup-file.md).
- `!n` TAB puts submission n's source into the edit buffer.
- ↑/↓ history does not wrap.
- `!n` and `!!n` are directives only when they are the entire line (surrounding
  spaces allowed). `"!0"` or `say 1; !0` is ordinary code.

## Notes

- n is the prompt number: `[n] >`.
- `!n` echoes the recalled source before running it, and the new run becomes a new
  submission. `!!n` prints nothing.
- Unknown n: `irak: no submission n`, `irak: no value for submission n`.
- TAB goes through the line editor's completion, which replaces the whole buffer.
  It is untested: Terminal::LineEditor waits for a cursor-position reply that
  script(1) never gives, so the test runs without a line editor.
- ↑/↓ needed no change: Terminal::LineEditor's history already stops at both ends.
- Implementation: `src/core.c/REPL.rakumod` (`%!irak-sources`, `irak-recall`,
  the directive check in `repl-loop`).
