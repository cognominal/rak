# 02: Output redirection keeps the statement's own writing behaviour

**What to build:** `STMT >out.txt` and `STMT >>out.txt` write the statement's output to the
file without changing what the statement prints. Concretely: `print foo >out.txt` writes
`foo` and no trailing newline; `say foo >out.txt` still writes a newline; a routine that
writes to standard error is not captured by a standard-output redirection; the file is
complete on disk when the program ends, including when the program ends by throwing. A
target that cannot be written fails with a Raku file error naming the target instead of
producing a silent success.

**Blocked by:** 01 (the binding model decides what "the statement's output" means)

**Status:** resolved

- [X] `print`, `say` and a two-argument call each land the expected bytes, with the newline
      behaviour of the invoked routine preserved.
- [X] A statement writing to standard error is unaffected by `>`.
- [X] Truncation and append behaviour are unchanged from the existing tests.
- [X] An unwritable target (for example a directory, or a path under a non-existent
      directory) produces an error naming the target, and the program exits non-zero.
- [X] A test pins down that redirected bytes are on disk after normal exit and after an
      exception.
- [X] Existing tests in `t/14-redirection/` still pass unmodified.

## Answer

The actions no longer re-aim the statement at the target. `redirected-statement` keeps the
statement's own AST and wraps it in a block that binds the stream variable to the target
for that statement: the declaration, then a guard that surfaces `open`'s Failure, then the
statement itself. `t/14-redirection/statement-stream.rak` (13 assertions) proves the newline
behaviour of `print` and `say`, two-argument calls, standard error staying out of the file,
the binding not outliving the statement, the enclosing `$_` still resolving, the missing
target error naming the target with a non-zero exit, bytes on disk after the statement and
after a throw. `basic.rak`, `append.rak`, `binary-ops.rak`, `edge-cases.rak` and
`gating.raku` pass unchanged.

Note: `open` returns a Failure rather than throwing, so the wrapper carries a guard
(`die $*OUT unless $*OUT.defined`) that turns it into a file error at the statement rather
than at the first write.
