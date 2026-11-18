# 09: `.jsonl` is a format with one record per line

**What to build:** a `.jsonl` entry in the format table. Writing an array in value mode
writes one compact JSON record per element; `>>` appends one record per line (a non-array
value is one record). Loading gives an array of records, for `@` and `$` alike. A bad line
fails with `X::Rak::Format::Decode` naming the line.

**Blocked by:** 05, 07

**Status:** ready-for-agent

**Tests:** `t/14-redirection/rak/012-jsonl.rak`

- [ ] `@a >a.jsonl` writes one compact record per line.
- [ ] `%h >>a.jsonl` appends one line; repeated appends accumulate.
- [ ] `my @r <a.jsonl` and `my $r <a.jsonl` both give the array of records.
- [ ] A malformed line fails with a decode error naming that line number.
