# 04: Captured command output keeps its trailing newline

Status: needs-triage

**Spec:** `rak-plans/features/commands.md`: when a command's value is used, its standard
output is captured as a `Str`. The spec does not say what happens to the final newline.

**Today:** the newline is kept, so a captured value cannot be passed on as is:

```
$ ./rak -e 'say (echo hi)->raku'
"hi\n"
$ ./rak -e 'my $d = (echo /tmp); cd $d'
Failed to change the working directory to '/tmp
': chdir failed: no such file or directory
```

**Proposal:** strip trailing newlines, as POSIX command substitution `$(…)` does, so
`(echo /tmp)` is `"/tmp"`. A multi-line output keeps its inner newlines.

**Open points:**
- All trailing newlines (POSIX) or exactly one?
- Does a pipeline whose last stage is a command, captured, behave the same?
- Values printed by irak and `@a = (ls)` (lines) are unaffected either way; check.

**Done when:** `(echo hi)` is `"hi"`, `my $d = (echo /tmp); cd $d` works, the rule is
written in `commands.md`, with a test in `t/15-commands/rak/`.
