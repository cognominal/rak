# 03: Input redirection reads a statement's input from a file

**What to build:** `<in.txt STMT` runs the statement with its standard input bound to
`in.txt`, so `<in.txt say $*IN.slurp` prints the file's contents and `<in.txt lines`
behaves like the same statement fed by a pipe. Today this spelling parses and then aborts
the compile with a panic; after this ticket it either works or fails as a Raku error, with
no "not yet implemented" path left. A missing or unreadable file fails with an error naming
the file, and `<` followed by whitespace or by a comparison stays a comparison.

**Blocked by:** 01 (the binding model decides what `<` binds)

**Status:** resolved

- [X] A new `t/14-redirection/input.rak` proves a statement reads its input from the file.
- [X] A missing file produces an error naming the file, not an empty read.
- [X] `$a < $b` keeps its existing meaning. (Comparison needs the whitespace the rak
      spelling rule asks for; `$a <$b`, with `<` touching, is a parse error rather than a
      comparison. That follows from the spacing-as-syntax rule and predates this ticket.)
- [X] No panic path remains for input redirection.
- [X] The gate still holds: `gating.raku` gained an assertion that `<file` is not input
      redirection in a `.raku` file.

## Answer

`<file STMT` now goes through the same wrapper as output redirection, with `$*IN` as the
bound stream and read-only mode. `t/14-redirection/input.rak` (7 assertions) covers a
statement printing what it read (captured through a rebound `$*OUT`), a statement storing
what it read, a multi-line read, `$*IN` being the same handle after the statement, a
missing file naming the file in its error, and `<` between values staying a comparison.
`gating.raku` grew to three assertions.
