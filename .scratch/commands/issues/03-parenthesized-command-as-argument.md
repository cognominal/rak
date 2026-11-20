# 03: A parenthesized command as an argument, `cd (zoxide query orbit)`

Status: needs-triage

**Spec:** `PLANS/features/commands.md`: when a command's value is used, as in
`my $out = (ls)`, its output is captured as a `Str`. Nothing says whether a
parenthesized command can be an argument of another command, the way `$(…)` is in a
POSIX shell.

**Today:** in the shell strategy, `(` cannot start an argument (`rak-piece` excludes
`(` and `)`), so the statement falls back to the standard strategy and fails:

```
$ ./rak -e 'cd (echo /tmp)'
===SORRY!=== Error while compiling -e
Two terms in a row
------> cd<HERE> (echo /tmp)
```

The workaround is two statements: `my $d = (echo /tmp)->trim; cd $d`.

**Why it matters:** the irak tutorial's tool list (chapter 16) has to say that
`zoxide` does not work in irak; `cd (zoxide query orbit)` would be the natural
spelling. The same goes for `vim (fzf)`, `cd (git rev-parse --show-toplevel)`.

**Open points:**
- Is `(…)` in argument position a captured command, a rak expression, or both (decided
  by the strategy of what is inside, as at statement level)?
- Does `(…)` glued to other text interpolate, as `foo-(date +%F).log`?
- Depends on 04: without trimming, `cd (echo /tmp)` would get `"/tmp\n"`.

**Done when:** `cd (echo /tmp)` changes to `/tmp`, with a test in
`t/15-commands/rak/`, and chapter 16 of the tutorials drops the zoxide caveat.
