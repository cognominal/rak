# 01: Decide what a redirection binds, and how far the binding reaches

**What to build:** a written decision, not code. Answer, for `>`, `>>` and `<`: which
stream is bound, for how long, and what the statement is allowed to rely on. The decision
lands as an ADR in `docs/adr/` and as an update to this effort's spec, and it is what
tickets 02 and 03 implement. The candidates on the table:

- Bind the statement's standard output stream for the duration of the statement, so the
  statement means exactly what it would have meant without the redirection (`print` keeps
  its missing newline, a routine writing to standard error stays on standard error), and
  `<` binds standard input the same way. This is the model the spec assumes.
- Keep today's shape, where the redirection re-aims one call by opening the target and
  sending the statement's value to it. Cheaper, but it changes the statement's meaning and
  has no answer for input.
- Treat a redirection as a process-wide binding for the rest of the program, which
  contradicts nothing in the existing tests but makes statement order load-bearing.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [X] The chosen model states what `>` and `>>` bind, and that `<` binds the input stream.
- [X] The model states whether the invoked routine's own stream choice is preserved.
- [X] The model states the binding's scope (statement, compilation unit, or process).
- [X] The rejected options and why they lost are recorded.
- [X] The decision is recorded as an ADR, and `spec.md`'s Implementation Decisions match it.

## Answer

Statement-scoped binding of the streams: `>` and `>>` bind standard output, `<` binds
standard input, the statement keeps its own writing behaviour, and the binding ends with
the statement. Recorded in `docs/adr/0002-redirection-binds-the-statement-stream.md`;
`spec.md` already describes this model. Tickets 02 and 03 are unblocked by this answer.
