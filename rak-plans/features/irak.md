# irak: the interactive session

Status: WIP, NEEDSPEC — the topic, `- `, pinning the topic (lone `-`, `! `), banner,
line editor and OSC 133 are implemented; a command's output as the topic is not (see
§ When a submission updates the topic). TAB completion is planned in
[completion](completion.md).

[irak](../../GLOSSARY.md#irak) is rak with no source file: the REPL, `-e` and standard input.
The `./rak` wrapper with no arguments starts it. Usage is in the
[cheat sheet](../../rak-docs/CHEATSHEET.md#irak-the-repl); this document covers the design.

## irak: the REPL as a pipe through time

In [irak](../../GLOSSARY.md#irak), the [irak topic](../../GLOSSARY.md#irak-topic) `$_` holds the value of the previous [irak
submission](../../GLOSSARY.md#irak-submission), so each submission works on the output of the one before.
This is the interactive habit of growing a pipeline one stage at a time,
but the values passed between stages stay structured.

### When a submission updates the topic

A submission updates the topic when the topic is unpinned and its value is shown: its
value becomes `$_`. Loading with `<file` (nothing on its left) also counts.

A submission whose output comes from commands updates the topic too: the
[external commands](../../GLOSSARY.md#external-command) it runs at statement level
write to the terminal as before, and what they wrote to standard output, as one `Str`
with its final newline removed, becomes `$_`. `ls` then `.lines.elems` counts the
files. Its `Proc` is not shown and is not the topic.

- Standard error is shown but not kept.
- The exit status does not matter: `grep` that exits 1 after printing lines still sets
  the topic. A command that writes nothing to standard output leaves `$_` alone.
- When several commands write, their outputs are joined in the order they ran.
- When Raku code in the same submission also prints (`say`), the output is not all
  from commands and `$_` is left alone.

A submission leaves `$_` alone when:

- it fails, or its value is `Nil`;
- Raku code in it prints output itself (`say`, `print`), so its value is not shown;
- it is the formatter `.`, which shows JSON;
- it is a [topic-keeping submission](../../GLOSSARY.md#topic-keeping-submission);
- the topic is [pinned](../../GLOSSARY.md#pinned-topic) and the submission is not a
  [topic-setting submission](../../GLOSSARY.md#topic-setting-submission).

In every case the value is still recorded, so `!!n` can make it the topic later; for a
submission of commands, the value recorded is their output.

Open: keeping a command's output means irak sits between the command and the terminal.
The command must still see a terminal, or `ls` stops using columns and colors and
full-screen programs (`vim`, `less`, `top`) break, so irak would run it on a
pseudo-terminal and copy its output through. What a full-screen program writes is
screen drawing, not output: irak should not keep it, for instance when the program
switches to the alternate screen. Whether to cap the size of the kept output is
also open.

### Pinning the topic

A lone `-` on the line of a fresh submission is not a submission: it toggles the pin.
It pins the topic when it is unpinned and unpins it when it is pinned. It gets no
number, runs nothing, and `!n` cannot recall it; irak answers `irak: topic pinned` or
`irak: topic unpinned`. A comment may follow it, `-   # look around`. Since `#` is also
the native-int sigil, the comment's `#` must come before a space or the end of the line:
`- #n` is a topic-keeping submission that shows `#n`.

While the topic is pinned, submissions run and show their values as usual, but `$_`
stays the value it had when it was pinned, so one value can be explored at length
without `- ` on every line. Two things still change it:

- a topic-setting submission, `! ` before the submission (see below);
- `!!n`, which sets `$_` to the value of submission `n`. The pin stays on, now
  holding that value.

While the topic is pinned, the prompt ends in `-`: `[3] >- `.

A session starts unpinned. The pin is not saved between sessions.

### Prefixes for one submission

Two prefixes act on one submission. Each counts only at the start of a fresh
submission, not on a continuation line; it is stripped before the submission runs and
kept in its recorded source, so `!n` replays it with the same effect and `!n` TAB
shows it.

- `- ` makes a topic-keeping submission: its value does not become `$_`, pinned or not.
  `- ls` shows the listing and keeps the topic.
- `! ` makes a topic-setting submission: its value becomes `$_` even while the topic is
  pinned. The pin stays on, now holding the new value. Unpinned, `! ` changes nothing.
  The other rules still apply: a failure, `Nil`, or a submission that prints its own
  output leaves `$_` alone even with `! `.

Only the automatic update depends on these: `- $_ = 3` and an assignment to `$_` while
pinned still assign.

Two Raku spellings lose their meaning at the start of an irak submission: prefix minus
followed by a space (`- 5`, write `-5`) and prefix negation followed by a space
(`! $x`, write `!$x`). A lone `-` was a syntax error, so the toggle takes nothing away.


## Line editing

irak edits with Terminal::LineEditor, whose input line is one scrolling row as wide as
the terminal was when the prompt appeared. irak adds terminal resizes: on SIGWINCH the
line is redrawn at the new width, keeping its text and cursor, and history recall uses
that width too. A terminal that reflows the old row may leave a fragment of it above
the redrawn prompt.

## Shell integration: OSC 133 marks

Status: **done** (`src/core.c/REPL.rakumod`, test
`t/02-rakudo/rak/028-irak-osc133.t`).

irak marks its prompts and outputs with the
[OSC 133](https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md)
semantic prompt sequences, as zsh, fish and bash do with their shell integration.
Terminals that read them (kitty, WezTerm, Ghostty, iTerm2, foot, VS Code) can then jump
from prompt to prompt, select a submission's output, and flag the submissions that failed.

| mark | sent |
|---|---|
| `A` | before the prompt |
| `B` | after the prompt |
| `C` | before the output |
| `D;n` | after the output |

Each mark is `ESC ] 133 ; <mark> ESC \`.

- **One command per submission.** A multi-line
  [irak submission](../../GLOSSARY.md#irak-submission) is one command: only its first
  prompt gets `A` and `B`. The continuation prompts stay bare.
- **When `C` goes out.** irak cannot tell a submission is complete until it has compiled
  it, and running follows compiling without a pause. So `C` is sent from the REPL's
  `ctxsave` hook, which the compiled code calls as it starts running. An incomplete
  submission never runs, so it never gets a `C` too early. A submission that fails to
  compile gets its `C` just before the error is shown.
- **Paging.** irak holds a submission's output to page it, so the marks bypass the
  page and go straight to the terminal. `C` comes before the held output, and a pager
  that runs, with its summary, comes before `D`.
- **The status in `D`.** A failed command's exit status, as `$?` holds it (`D;3` after
  `sh -c 'exit 3'`). Otherwise 1 when the submission threw or returned an unhandled
  `Failure`, else 0. The `!n`, `!!n` and `!p` directives also end with a `D`: 1 when
  the submission or output they name does not exist, or paging is off for `!p`.
- **`exit`.** A submission that calls `exit` gets a `C` but no `D`, since the process
  ends while it runs.
- **When marks are sent.** Only in irak, only with
  [Terminal::LineEditor](../build/AUR.md) as the line editor, and only when standard
  input and output are both a tty. `RAKUDO_DISABLE_OSC133=1` turns them off.

Terminal::LineEditor 0.0.23 lets `A` and `B` go inside the prompt string. Its `prompt`
method prints the string once, as is. Then `read-input` asks the terminal for the cursor
position (`ESC [6n`), and the input field starts at the column the terminal reports.
Escape sequences in the prompt are therefore never counted as width. Edits redraw only
the input field, by moving the cursor relative to where it starts, never the prompt. The
prompt is printed again only after a suspend (Ctrl-Z, then `fg`) and when irak redraws
the line after a terminal resize. Both reprint the prompt at the start of its line, so
sending `A` and `B` again is right.

Readline would need the marks wrapped in `\001`…`\002`, and Linenoise counts every byte
of the prompt as width, so irak sends no marks with them.

The test runs irak under `script(1)` and answers the editor's cursor queries itself. It
drives one prompt per session because of a Terminal::LineEditor 0.0.23 bug that rak's
patches leave in place. After a line
is read, its parser thread stays blocked in `$*IN.read(1)`. MoarVM serializes operations
on a handle, so the next prompt's `$*IN.t` waits for that read. By then the tty is back
in cooked mode, so the read returns only once a whole line is typed. Under a harness
that waits for the prompt before typing, the second prompt stalls. How this shows in a
real terminal has not been checked. The multi-line case is therefore tested up to the
continuation prompt. Repro: `start { $*IN.read(1) }; sleep 1; $*IN.t` blocks until input
arrives.

## Completion

TAB completes the word under the cursor through fzf, which previews the value behind
each key or index: see [completion](completion.md). The former TAB / SHIFT-TAB design
is in the [archive](../archive/irak-navigation.md).
