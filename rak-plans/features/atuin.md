# atuin: one history across shells

Status: WIP — recording is tested by `t/02-rakudo/rak/031-irak-atuin.t`. The importer
lives on the `rak` branch of [cognominal/atuin](https://github.com/cognominal/atuin).
Search is not implemented.

[Atuin](https://atuin.sh) keeps shell history in a SQLite database, searches it with a
TUI, and optionally syncs it end to end. irak keeps its own history in
`$XDG_STATE_HOME/rak/history` ([the startup file](startup-file.md)). This feature joins
the two without making atuin a dependency of rak.

## Import

`atuin import irak` adds irak's history to atuin's database:

- it reads `$XDG_STATE_HOME/rak/history`, default `~/.local/state/rak/history`;
- the file holds one line per history entry, so a multi-line
  [submission](../../GLOSSARY.md#irak-submission) appears as its lines; empty and
  invalid UTF-8 lines are skipped;
- the file has no timestamps, so the entries are spaced one millisecond apart and end at
  the import time;
- each entry records the shell as `irak`, so search can filter on it;
- there is no fallback to `~/.raku/irak-history`, since rak does not migrate that file
  either ([ADR 0006](../../docs/adr/0006-rak-user-files-follow-xdg-on-every-platform.md)).

The importer lives in atuin (`crates/atuin-client/src/import/irak.rs`), not in rak.
irak itself does not know that atuin exists.

## Live history

irak records each finished submission in atuin while it runs:

- Recording is on when `atuin` is on `PATH` and stdin is a tty.
  `RAKUDO_DISABLE_ATUIN` turns it off, as `RAKUDO_DISABLE_OSC133` does for OSC 133.
- At the first prompt, irak runs `atuin uuid` once. Every atuin call of the session
  gets that value as `ATUIN_SESSION`, and `ATUIN_SHELL=irak`. These variables are
  passed only to atuin, so the commands that irak runs keep the parent shell's
  environment.
- A whole submission is one entry. A multi-line submission keeps its newlines, and the
  `- ` or `! ` topic prefix stays in the text, so the entry runs the same way again.
- A `!n` re-run records the recalled source. Directives that run no code are not
  recorded. For example, a lone `-`, `!p` and `!!n` are not recorded.
- After the submission, irak runs `atuin history start --hook -- <submission>` and
  then `atuin history end --hook --exit <status> --duration <ns> -- <id>`.
- The status is the one that OSC 133 reports: a failed command's exit status, else 1
  when the submission threw or returned an unhandled Failure, else 0.
- The duration is the time irak spent evaluating the submission's code. It excludes
  the user's typing and the pager.
- Both calls run in the cwd of the submission, on another thread, one record after
  the other. The prompt never waits for atuin, and atuin's errors are dropped. When the
  loop ends, irak waits up to five seconds for the pending records.

`atuin history start` stamps the entry when it runs, so the timestamp is the end of
the submission rather than its start. The difference is the duration.

`exit` stops the process at once. A record that is still pending at that moment is
lost.

The history file and atuin overlap, so `atuin import irak` after a session with
recording on adds the session's submissions a second time.

## Search

`atuin search` is a full-screen TUI. A key binding in irak's line editor would hand the
terminal over, run `atuin search --interactive`, and insert the selection into the
buffer. Terminal::LineEditor leaves `Ctrl-R` unbound, so atuin can take it.

Terminal::LineEditor's input thread used to read stdin one byte at a time and check
whether to stop only after each byte. After leaving raw mode, the thread stayed blocked
in `read`, and it took the first byte meant for the next reader. For `atuin search`,
that byte would be either the user's first key or the first byte of crossterm's
cursor-position reply. rak's patch of Terminal::LineEditor
(`tools/build/rak-line-editor-patches/`) now makes the thread wait with `poll(2)` in
short slices, so a program run after leaving raw mode gets all of its input. The
binding itself is not written yet.

## Decisions

- **Optional.** rak works without atuin. The integration is discovered at run time
  (`atuin` on `PATH`) and is never a build dependency.
- **History is state.** irak's history is `$XDG_STATE_HOME/rak/history`
  ([ADR 0006](../../docs/adr/0006-rak-user-files-follow-xdg-on-every-platform.md)).
  `RAKUDO_HIST` is ignored, and rak defines no `RAK_*` override.
- **One-way import.** atuin's database is a copy for search and sync; irak still owns
  its history file. Pruning atuin does not touch the file.
- **Sync is atuin's.** When the user syncs, irak submissions leave the machine. rak
  never turns sync on.
- **`!n` and `!!n` stay irak's.** Atuin's search is a separate interaction, and irak's
  [submission numbering](irak-history.md) does not depend on atuin.

## Open questions

- Should the parser fix in rak's Terminal::LineEditor patch go upstream?
- Should the importer accept `~/.raku/irak-history` when the XDG file is missing?
  ADR 0006 says no migration, but a fallback in atuin would ease the transition.
