# 01: [RFE] In irak, add feedback before submission

Status: needs-triage

**GitHub:** https://github.com/cognominal/rak/issues/1

**Request:** show the user how irak will read an irak submission before it runs it.

- A single Enter does not evaluate the submission. It rewrites it in place:
  - it inserts a `my` declarator before each undeclared variable;
  - it colors every word by what it denotes, so that a word meant as a naked string
    but read as a keyword, a routine or a command stands out.
- A second Enter within one second evaluates the submission.

```
> $files = ls          ← typed, then Enter
> my $files = ls       ← `my` inserted, `ls` colored as a command; Enter again runs it
```

| Word         | Example        |
|--------------|----------------|
| keyword      | `if`, `given`  |
| routine      | `say`, `lines` |
| command      | `ls`, `^grep`  |
| naked string | `hello`        |
| undeclared   | `$ctiy`        |

**Today:** an undeclared variable is a compile error, and the user learns how a word
was read only from the result:

```
$ ./rak -e '$x = 1'
===SORRY!=== Error while compiling -e
Variable '$x' is not declared. ...
------> <BOL><HERE>$x = 1
```

**Why it matters:** irak submissions are throwaway scripts (ROADMAP), so declaring each
variable is ceremony. Worse, whether a word is a naked string depends on context and on
what is already known (GLOSSARY, naked string): `ls` alone runs the command, `say ls`
prints `ls`, `say if` is a syntax error, and `hello` stops being a string once a
`sub hello` is declared. The colors make that visible before anything runs.

## Proposed behavior

- **Where `my` goes:** before the first occurrence of each undeclared variable, and only
  where a declaration can stand: the left side of `=` or `:=`. Elsewhere (`@a.push: 3`,
  `say $x`) the variable is only colored as undeclared, and the second Enter gives
  today's error.
- **Typos:** no `my` when the resolver suggests a declared name. `say $ctiy` with `$city`
  declared stays as is, colored as undeclared: the irak tutorial (§7.1) teaches that
  this error "protects you from typos", and an inserted `my` would hide it.
- **Never declared:** variables with a twigil (`$*FOO`, `$!x`, `$^a`) and the rak
  variables `$?` and `@?`.
- **The second Enter:** it evaluates only if the buffer is unchanged since the first one
  and less than a second has passed. Otherwise it counts as a new first Enter: irak
  analyzes the buffer again and restarts the one-second window.
- **Incomplete submissions:** when the submission is not complete yet (irak would show
  its continuation prompt `* `), a single Enter continues as today. The analysis covers
  the whole submission, but it rewrites and colors only the line being edited, since the
  earlier lines are already printed.
- **Unchanged:** `!n` and `!!n` directives, empty input, irak without a terminal (`-e`,
  standard input) and the other line editors (Readline, Linenoise, the fallback).
- **History:** history records the evaluated text, `my` included.

## How I would implement it

All in `src/core.c/REPL.rakumod`, plus one small change to Terminal::LineEditor.

### 1. The analysis: a function with no terminal in it

`method irak-feedback(Str $submission --> Map)` returns the rewritten text, the colored
spans (`from`, `to`, class), and whether the submission is incomplete. It compiles the
submission against the same `outer_ctx` as `new-repl-eval`, but never runs it.

- **Undeclared variables:** the rak grammar panics on the first one
  (`typed-panic 'X::Undeclared'` in `src/Rak/Grammar.nqp`) and the exception has the
  position (the `<HERE>` above). So: compile, catch `X::Undeclared`, insert `my` at its
  `pos` if the rules above allow it, compile again; stop at the first error that is not
  an `X::Undeclared` or at a variable that must not be declared. Each round fixes one
  variable, so the loop is bounded by their number.
- **Colors:** the rak grammar decides each word's class in a few places: keywords in
  `rak-keywords` and `end-keyword`, commands in `rak-command` / `rak-is-command`, naked
  strings in `term:sym<rak-string>` and `rak-naked-word`, and known names through
  `$*R.is-identifier-known`. Collect the spans from the final match tree, which holds
  only what actually parsed, rather than from side effects in the grammar, which could
  record spans from branches that later backtracked.
- **Compile-time code:** compiling runs `BEGIN` blocks, `use` and `constant`
  initializers. The analysis would run them once more before the evaluation. Either
  accept that or skip feedback for submissions that contain them (open point).

### 2. Enter: one hook in Terminal::LineEditor

In Terminal::LineEditor 0.0.23, `CLIInput.read-input` maps Ctrl-M and Ctrl-J to the
`finish` action, which its `react` loop handles in place and which always ends input.
There is no way to keep editing after Enter. Two options:

- **Upstream hook (recommended):** a PR to Terminal::LineEditor adding an `&on-finish`
  callback to `read-input`/`prompt`. It is given the buffer, and returns either `True`
  (finish) or a new string (replace the buffer and keep editing). Input validation is
  a general need, so it has a fair chance of being merged. Until it is released, pin the
  patched dist in `tools/build/rak-line-editor-dists`.
- **Subclass:** override `read-input` in rak. It is about 150 lines to copy, which break
  silently on the next upgrade.

In `TerminalLineEditorBehavior.repl-read`, the callback keeps the time and text of the
last Enter. On a second Enter with the same text, less than a second later, it returns
`True`. Otherwise it calls `irak-feedback`, records the time, stores the spans and
returns the rewritten text.

### 3. Colors: a subclass of the input field

`CLIInput` takes an `:input-class`. A subclass of
`ScrollingSingleLineInput::ANSI` overrides `visible-input-field-string` to wrap the
visible part of each span in SGR codes. That method only builds the string; the widths
and cursor moves are computed earlier from the plain buffer (`DuospaceLayoutCache`), so
the zero-width escape codes do not disturb the cursor. It must clip spans to the
scrolled window and reset the color before the scroll marks. Any edit drops the spans;
coloring as you type is a possible follow-up. Respect `NO_COLOR`.

## Done when

- A single Enter rewrites and colors, and a second Enter within a second evaluates, in
  irak on a terminal with Terminal::LineEditor. Every other irak path is unchanged.
- Tests in `t/02-rakudo/rak/` call `irak-feedback` directly:
  - `$x = 1` gives `my $x = 1`;
  - `$x = 1; $x++` declares only the first occurrence;
  - `say $ctiy` with `$city` declared is unchanged, with `$ctiy` undeclared;
  - `say hello` colors `hello` as a naked string, but as a routine after `sub hello {}`;
  - `ls` colors a command, `say if` a keyword.
- The Enter logic is tested with an injected clock: same text within the window
  finishes; an edit, or more than a second, analyzes again.
- `CHEATSHEET.md` and the irak tutorial describe the double Enter.
