# 09: `.jsonl` is a format with one record per line

**What to build:** a `.jsonl` entry in the format table. Writing an array in value mode
writes one compact JSON record per element; `>>` appends one record per line (a non-array
value is one record). Loading gives an array of records, for `@` and `$` alike. A bad line
fails with `X::Rak::Format::Decode` naming the line.

**Blocked by:** 05, 07

**Status:** resolved

**Tests:** `t/14-redirection/rak/012-jsonl.rak`

- [X] `@a >a.jsonl` writes one compact record per line.
- [X] `%h >>a.jsonl` appends one line; repeated appends accumulate.
- [X] `my @r <a.jsonl` and `my $r <a.jsonl` both give the array of records.
- [X] A malformed line fails with a decode error naming that line number.

## Answer

All in `src/core.c/Rakudo/Internals/RakFormat.rakumod`. `RakFormat.of` maps `.jsonl` to
`jsonl`. `encode` writes one compact record per line: a list is one record per element,
anything else (including a hash) one record; the encoder gained a `:compact` mode.
`decode` decodes each non-blank line with the relaxed decoder and returns the array of
records; a bad record is rethrown as `X::Rak::Format::Decode` with format `jsonl` and the
file's line number ("bad.jsonl: invalid JSONL at line 2, column 6: ..."). In
`RAK-REDIRECT-OUT`, `>>` is refused only for `.json`; for `.jsonl` the records are encoded
first and then appended. Text mode works the same as for JSON: printed JSON Lines are
decoded and re-written compact. Load needs no change: `@` and `$` get the array, `%` is a
shape error. `t/14-redirection/rak/012-jsonl.rak`: 6/6.
