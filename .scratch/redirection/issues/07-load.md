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

**Status:** ready-for-agent

**Tests:** `t/14-redirection/rak/010-load.rak`, `t/14-redirection/rak/007-gating.raku`

- [ ] `my @a <a.json`, `my %h <h.json`, `my $x <x.json`, `%h.users <u.json` all load.
- [ ] Relaxed JSON loads.
- [ ] Sigil mismatches fail with `X::Rak::Format::Shape` naming the target and both types.
- [ ] Invalid JSON fails with `X::Rak::Format::Decode` including line and column.
- [ ] `my @l <f.txt` gives lines; `my $s <f.txt` gives the whole text.
- [ ] `<file STMT` (input redirection) is unchanged.
- [ ] `.raku`: `my @a <a.json` does not load.
