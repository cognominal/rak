# 05: A `.json` target gets the statement's value when nothing is printed

**What to build:** the format table (extension → format, case-insensitive, resolved at run
time so `>$f` works) with `.json` as its first entry, and value mode
(`docs/adr/0004-format-targets-write-the-value-when-nothing-is-printed.md`): `@a >a.json`
writes `@a` as JSON. Output is pretty-printed, 2-space indent, sorted keys, trailing newline,
using the core JSON code (`Rakudo::Internals::JSON`). Writes to a format target go through a
temporary file that replaces the target only on success. Targets with no format behave
exactly as today (`$x >f.txt` still leaves an empty file).

**Blocked by:** None

**Status:** ready-for-agent

**Tests:** `t/14-redirection/rak/008-json-value.rak`

- [ ] `@a >a.json`, `%h >h.json`, `$x >x.json` write the value as JSON; keys are sorted.
- [ ] `.JSON` is recognised; `>$f` with `$f = 'v.json'` is recognised at run time.
- [ ] `Any` is written as `null`; `Int`, `Rat` (shortest exact decimal; `1/3` as a float)
      and `Bool` are written natively.
- [ ] A value with no JSON form (`Set`, `Inf`, an arbitrary object) fails with
      `X::Rak::Format::Encode`, and an existing target is left untouched.
- [ ] `$x >f.txt` still writes nothing (ADR 0002 unchanged for plain targets).
