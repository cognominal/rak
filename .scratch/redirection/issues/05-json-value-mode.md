# 05: A `.json` target gets the statement's value when nothing is printed

**What to build:** the format table (extension → format, case-insensitive, resolved at run
time so `>$f` works) with `.json` as its first entry, and value mode
(`docs/adr/0004-format-targets-write-the-value-when-nothing-is-printed.md`): `@a >a.json`
writes `@a` as JSON. Output is pretty-printed, 2-space indent, sorted keys, trailing newline,
using the core JSON code (`Rakudo::Internals::JSON`). Writes to a format target go through a
temporary file that replaces the target only on success. Targets with no format behave
exactly as today (`$x >f.txt` still leaves an empty file).

**Blocked by:** None

**Status:** resolved

**Tests:** `t/14-redirection/rak/008-json-value.rak`

- [X] `@a >a.json`, `%h >h.json`, `$x >x.json` write the value as JSON; keys are sorted.
- [X] `.JSON` is recognised; `>$f` with `$f = 'v.json'` is recognised at run time.
- [X] `Any` is written as `null`; `Int`, `Rat` (shortest exact decimal; `1/3` as a float)
      and `Bool` are written natively.
- [X] A value with no JSON form (`Set`, `Inf`, an arbitrary object) fails with
      `X::Rak::Format::Encode`, and an existing target is left untouched.
- [X] `$x >f.txt` still writes nothing (ADR 0002 unchanged for plain targets).

## Answer

Output redirection now compiles to `RAK-REDIRECT-OUT(target, mode, { STMT })`, a setting
helper in `src/core.c/Rakudo/Internals/RakFormat.rakumod`, so the format is chosen at run
time. A target with no format streams through a bound `$*OUT` exactly as before. A `.json`
target binds `$*OUT` to an in-memory capture; if nothing was printed, the value is encoded
by a rak encoder (the core `Rakudo::Internals::JSON` loses precision on `Rat`s, writes
`Inf` as `null` and emits invalid JSON for a `Set`; only its string escaping is reused).
The result is spurted to a temporary file and renamed over the target. `X::Rak::Format`
and `X::Rak::Format::Encode` are defined there too. Printed text currently goes to the
target unchecked; issue 06 adds the decode check. `>>` to a `.json` target already fails
(issue 06's last box). `t/14-redirection/rak/008-json-value.rak`: 13/13.
