# Redirection binds the statement's stream, not the statement's value

`STMT >file` and `STMT >>file` bind the standard output stream to the target for the
duration of that one statement, and `<file STMT` binds the standard input stream the same
way. The statement keeps its own writing behaviour: `print foo >out.txt` writes no
trailing newline, and a routine that writes to standard error is not captured by a
standard-output redirection. The binding ends when the statement does, so the next
statement prints to the terminal again.

## Considered Options

- **Re-aim the statement's value at the target handle** (the shape this branch shipped
  first: open the target and call `say` on it). Rejected: it is not redirection, it is
  `say` to a file. It silently replaces the invoked routine, so `print` gains a newline and
  `note` lands in the file instead of on standard error, and it has no counterpart for
  input at all.
- **Bind process-wide from the first redirection onwards.** Rejected: a redirection inside
  a helper would change the behaviour of everything after it, making statement order, and
  therefore the position of the redirection, load-bearing.

## Consequences

- The statement's own AST is preserved and wrapped in a dynamic binding; redirection can no
  longer be implemented by rewriting the callee, so the AST rewrite that does it today has
  to go.
- The binding's end (statement end) is also the point where the target is closed, so that
  is where an I/O failure surfaces, and where the bytes reach disk.
- `$*OUT` and `$*IN` stay the only stream surface: no new stream API is introduced.
- Because the binding is dynamic and per-statement, the same statement can be redirected
  differently in two places in one file with no interference.
- A statement that produces no output writes nothing: `$x >f` leaves an empty file. (For
  a target with a format, see `docs/adr/0004-format-targets-write-the-value-when-nothing-is-printed.md`.) The earlier `say`-shaped rewrite wrote the
  statement's value, so this is a visible change of meaning, and the intended spelling for
  writing a value is `say $x >f`.
