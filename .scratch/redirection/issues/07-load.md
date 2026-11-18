# 07: `LVALUE <target` loads a file into anything assignable

**What to build:** the load form. A `<` touching its target at the end of a statement,
with something before it, assigns the decoded content to the left-hand side, which may be
any assignable expression including a declaration (`my %cfg <cfg.json`) or a subscript.
JSON is decoded with the same relaxed decoder as 06. Sigils are checked strictly: `@` needs
an array, `%` an object, `~`/`#` a string/integer, `$` accepts anything; a mismatch fails
with `X::Rak::Format::Shape` ("cfg.json: expected a JSON object for %cfg, found an array").
A target with no format loads as lines for `@` and as one string for `$`. `<` touching its
target is always a load; a numeric right-hand side warns. Load cannot be combined with
output redirection in the same statement (for now). Gated: `.raku` files do not get it.

**Blocked by:** 05 (format table)

**Status:** resolved

**Tests:** `t/14-redirection/rak/010-load.rak`, `t/14-redirection/rak/007-gating.raku`

- [X] `my @a <a.json`, `my %h <h.json`, `my $x <x.json`, `%h.users <u.json` all load.
- [X] Relaxed JSON loads.
- [X] Sigil mismatches fail with `X::Rak::Format::Shape` naming the target and both types.
- [X] Invalid JSON fails with `X::Rak::Format::Decode` including line and column.
- [X] `my @l <f.txt` gives lines; `my $s <f.txt` gives the whole text.
- [X] `<file STMT` (input redirection) is unchanged.
- [X] `.raku`: `my @a <a.json` does not load.

## Answer

Grammar: `statement-mod-load` in `src/Rak/Grammar.nqp`, tried after `<EXPR>` before
`statement-mod-redir`: `<` touching a `redir-filename` at the end of the statement. A
digit-led target (`$a <5`) also loads, with a compile-time worry suggesting a space for
comparison. `<file STMT` is untouched (it is matched at the start of the statement).

Actions: `load-expression` in `src/Rak/Actions.nqp` rewrites `LVALUE <target` to
`LVALUE = RAK-LOAD(target, sigil, name)` (list assignment for `@`/`%`, item otherwise). The
sigil and name come from a declared or plain variable on the left; any other left-hand
side (subscript, call) counts as `$`. Because it is a real assignment, native `#`/`~`
variables load too.

Runtime: `RAK-LOAD` and `X::Rak::Format::Shape` in
`src/core.c/Rakudo/Internals/RakFormat.rakumod`. A target with a format is decoded with the
relaxed decoder from 06; the shape is checked for `@` (array), `%` (object), `~` (string),
`#` (integer), e.g. "cfg.json: expected a JSON object for %cfg, found an array". Without a
format, `@` gets lines, `#` the trimmed text as an Int, `$`/`~` the whole text, `%` a shape
error. `t/14-redirection/rak/010-load.rak`: 15/15; `007-gating.raku` 4/4. The numeric
warning has no automated test.
