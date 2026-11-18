# Redirection

**Status:** ready-for-agent

## Problem Statement

A `.rak` script can already send a statement's output to a file (`say foo >out.txt`), but
the feature stops there in three visible ways. There is no way to take input from a file:
`<in.txt` parses and then aborts the compile with a "not yet implemented" panic. The write
path re-shapes the statement it is attached to, so `print foo >out.txt` gains a newline,
and a routine that writes somewhere other than standard output loses that distinction. And
the target spelling is narrower than the documented set: paths written as `./x`, `../x` or
`~/x` do not parse as targets, and neither does any subscripted form (`$file` works,
`.name` and `@files[0]` do not). Behind all three sits an unanswered question: what does a
redirection actually bind, the output of one routine call, or the statement's output
streams?

## Solution

Redirection becomes a statement-level binding of the streams, available in rak mode only:
`STMT >target` / `STMT >>target` send the statement's standard output to the file,
`<target STMT` takes its standard input from the file, and the statement keeps the
semantics it would have had without the redirection. Targets accept the full documented
spelling set. Opening a target that cannot be written, or reading one that does not exist,
fails as an ordinary Raku error naming the file.

## User Stories

1. As a `.rak` script author, I want `say foo >out.txt` to write `foo` to `out.txt`, so that I can keep long output out of the terminal.
2. As a `.rak` script author, I want `>out.txt` to truncate an existing file, so that a rerun does not accumulate stale content.
3. As a `.rak` script author, I want `say foo >>out.txt` to append, so that I can build a log across runs.
4. As a `.rak` script author, I want `<in.txt say $*IN.slurp` to read `in.txt`, so that a script can be fed input without shell plumbing.
5. As a `.rak` script author, I want redirection to work on any statement, not just on `say`, so that I do not have to restructure code around the feature.
6. As a `.rak` script author, I want `print foo >out.txt` to write `foo` with no trailing newline, so that output redirection does not change what the statement prints.
7. As a `.rak` script author, I want a routine that writes to standard error to keep writing there, so that a redirection of standard output does not silently capture the wrong stream.
8. As a `.rak` script author, I want `say foo >'my file.txt'` and `say foo >$file` to work, so that targets with spaces come from quoting and dynamic targets come from variables.
9. As a `.rak` script author, I want `say foo >./out.txt`, `>../out.txt` and `>~/out.txt` to work, so that I can name a path relative to the script, its parent, or my home.
10. As a `.rak` script author, I want `say foo >.conf<output>` and `say foo >@files[0]` to work, so that the dotty subscript and array subscripts are usable as targets.
11. As a `.rak` script author, I want `$a > $b` with spaces around the operator to stay a comparison, so that existing Raku code in a `.rak` file keeps its meaning.
12. As a `.rak` script author, I want `<` not to be mistaken for input redirection when it is a comparison, so that `$a < $b` is unaffected.
13. As a `.rak` script author, I want a redirection in the middle of a statement to be a syntax error rather than a silent surprise, so that mistakes surface at compile time.
14. As a `.rak` script author, I want redirecting into an unwritable path to fail with an error naming the path, so that I can tell a redirected run apart from a successful one.
15. As a `.rak` script author, I want input redirecting from a missing file to fail the same way, so that an empty result is never mistaken for an empty file.
16. As a `.rak` script author, I want everything written by a redirected run to be on disk when the program ends, including after an exception, so that output is not lost to an uncleared buffer.
17. As a Raku programmer, I want redirection to remain unavailable in `.raku`, `.rakumod`, `.pm6` and `.nqp` files, so that my modules cannot be reinterpreted by this fork.
18. As a `rak` REPL user, I want the same redirection spellings at the prompt, so that the feature is not file-only.
19. As a `.rak` script author, I want a redirection target that is a naked string to combine with naked-string content (`say foo >out.txt`), so that the two features read as one syntax.
20. As a maintainer of this branch, I want the semantics of `>`, `>>` and `<` written down in one place, so that the next ticket does not have to re-derive them from the parser.

## Implementation Decisions

- **Redirection stays a statement-level construct.** No expression form, no mid-statement
  position, and no stream object handed to the user. This keeps the parser change local to
  the statement rule.
- **The gate is the existing rak mode flag.** All new spellings hang off the same gate the
  new sigils and dotty subscript use (see ADR-0001); `.raku` files must be unaffected.
- **The redirection operator binds by touch.** An operator touching its target on the
  right is a redirection; whitespace after the operator returns it to its Raku meaning, so
  comparison spellings keep working. The rule is applied at the statement level, where the
  target is a single token.
- **The statement is compiled, then its streams are bound around it.** The rewrite happens
  in the RakuAST actions' statement handling: the statement's own AST is kept, and the
  redirection becomes a dynamic binding of the standard output stream (input stream for
  `<`) for the duration of that statement. The invoked routine is never substituted: the
  callee's own writing behaviour, including writing to standard error, survives.
- **Scope is the statement, not the process.** The binding is dynamic and ends with the
  statement, so a later statement without a redirection prints to the terminal again.
- **Targets are opened with explicit modes**: truncate for `>`, append for `>>`, read for
  `<`. The handle is closed when the statement ends, which is also what puts the bytes on
  disk; failure to open or close propagates as the usual Raku file error naming the target.
- **Target spellings**: naked string, quoted string (with the usual escapes), scalar
  variable, array or hash subscript, and the dotty subscript. The naked-target rule must
  match its own documentation, so relative and home-relative paths (`./`, `../`, `~/`) are
  targets, not parse errors.
- **`$*IN`, `$*OUT` and `$*ERR` remain the ordinary Raku streams.** Redirection binds them
  for the statement; it does not introduce a new stream API.

## Testing Decisions

- **Good test here means**: run a `.rak` program and observe the filesystem and the
  process's output. File contents, file existence, exit status and the error class are the
  assertions; nothing asserts on how the statement was rewritten.
- **One seam, and it already exists**: the compiler's public surface, driven exactly the
  way the existing redirection tests drive it, by compiling a `.rak` file with the `rak`
  wrapper and asserting with `Test`. No new seam is introduced.
- **Prior art**: `t/14-redirection/basic.rak`, `append.rak`, `binary-ops.rak` and
  `edge-cases.rak` for the write path, and `t/14-redirection/gating.raku` for the claim
  that ordinary Raku files are unaffected. The input path adds a sibling file in the same
  shape; each ticket extends these files rather than starting a new test style.
- **Each redirection ticket lands its own assertions**, on the same public seam, so a
  ticket that stops half way still leaves the earlier behaviour proven.

## Out of Scope

- Pipelines, process substitution, and redirecting the output of one command into another.
- Globbing, and any expansion of the target beyond the spellings listed above.
- Redirection of standard error or of file descriptors by number (`2>`), unless ticket 01
  of this effort decides otherwise.
- Here-documents and here-strings.
- Redirection to or from a network or in-memory stream.
- Shell mode's command launching and builtins: this effort is about the redirection
  spelling, not about running programs.
- Loading `src/Rak/` as the rak frontend itself. Done, and recorded in
  `docs/adr/0003-rak-keeps-its-own-grammar-and-actions.md`: the `rak` wrapper selects the
  `Rak::*` pair, which is a regenerated twin of `Raku::*` and so carries this work.

## Further Notes

- Source material: `PLANS/archive/RAKFILE.md` (the original design sketch, including the
  statement-position table and the equivalent-forms list) and `PLANS/status.md` for the
  branch-wide picture.
- Tickets 02 and 03 are done. Both spellings go through one wrapper that keeps the
  statement's own AST and binds the stream variable around it; the tests that prove it are
  `t/14-redirection/statement-stream.rak` (13 assertions) and `input.rak` (7). Run them with
  `./rak -Ilib t/14-redirection/<file>.rak`; `gating.raku` needs the plain frontend
  (`RAKUDO_RAKUAST=1 ./rakudo-m -Ilib t/14-redirection/gating.raku`), because the `rak`
  wrapper's rak-mode environment variable would leak into its `EVAL`.
- Still open for ticket 04: the naked-target rule's comment promises `./`, `../` and `~/`
  spellings the rule itself does not accept, and a double-quoted target (`>"out.txt"`) is a
  parse error, since only single quotes are matched today.
- Consequence of the binding model, worth stating in user-facing prose: a statement that
  produces no output now writes nothing at all. `$x >f` leaves an empty file and warns
  about a useless use in sink context, where the old `say`-shaped rewrite wrote the value.
  Redirecting a value is not redirection; `say $x >f` is.
- Flushing is observed rather than assumed: the target is complete and readable right after
  the statement, and content written before a throw is on disk.
- The rak spelling rule that binary operators need whitespace makes `$a <$b` a parse error
  while `$a < $b` stays a comparison. That is pre-existing behaviour, not a redirection
  decision; `input.rak` asserts the spaced form.
- Vocabulary for titles and criteria comes from `GLOSSARY.md`; the gate decision is recorded
  in `docs/adr/0001-single-rak-gate.md`, the binding model in `0002`.
