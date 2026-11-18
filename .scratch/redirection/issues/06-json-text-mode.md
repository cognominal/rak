# 06: Printed output to a `.json` target must be JSON, and is normalised

**What to build:** text mode for format targets. When the redirected statement prints, the
printed text is collected, decoded with the relaxed JSON decoder (unquoted keys, single
quotes, trailing commas), and written re-encoded as standard JSON. `print "{ a: 'a' }"
>a.json` writes `{"a": "a"}`. Text that does not decode fails with
`X::Rak::Format::Decode` naming the target, the format, and line/column, and leaves the
existing file untouched. `>>` to a `.json` target is an error.

**Blocked by:** 05 (format table, atomic write)

**Status:** resolved

**Tests:** `t/14-redirection/rak/009-json-text.rak`

- [X] Strict JSON printed is written back as standard JSON.
- [X] Relaxed JSON (`{ a: 'a' }`, trailing comma) is accepted and normalised.
- [X] `say @a >a.json` prints a gist that is not JSON, so it fails with a decode error.
- [X] A statement that prints *and* returns a value is in text mode.
- [X] Decode failure leaves an existing target byte-for-byte untouched.
- [X] `say 1 >>a.json` fails; the error mentions `.jsonl`. (Done with 05.)

## Answer

`Rakudo::Internals::RakJSONDecoder` in `src/core.c/Rakudo/Internals/RakFormat.rakumod` is a
hand-written relaxed decoder: standard JSON plus identifier keys, single-quoted strings,
trailing commas, a leading `+`, and `//` / `/* */` comments. It reports
`X::Rak::Format::Decode` with the target, `JSON`, line and column. In `RAK-REDIRECT-OUT`,
printed text for a format target is decoded and re-encoded with the same encoder as value
mode, so the file always holds standard, sorted, pretty JSON; because the write is atomic,
a decode failure leaves the old file untouched. Issues 07-09 reuse the decoder.
`t/14-redirection/rak/009-json-text.rak`: 9/9.

## Decided: no special treatment for `{ }` in double quotes

`print "{ a: 'a' }" >a.json` runs the block inside the string, as in Raku, and prints
`a`, which is not JSON. The user decided (2026-11-18) that rak keeps this behaviour. To print
literal JSON, use single quotes or `q[...]`: `print '{ a: "a" }' >a.json`.
