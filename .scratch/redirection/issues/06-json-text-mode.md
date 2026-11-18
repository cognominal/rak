# 06: Printed output to a `.json` target must be JSON, and is normalised

**What to build:** text mode for format targets. When the redirected statement prints, the
printed text is collected, decoded with the relaxed JSON decoder (unquoted keys, single
quotes, trailing commas), and written re-encoded as standard JSON. `print "{ a: 'a' }"
>a.json` writes `{"a": "a"}`. Text that does not decode fails with
`X::Rak::Format::Decode` naming the target, the format, and line/column, and leaves the
existing file untouched. `>>` to a `.json` target is an error.

**Blocked by:** 05 (format table, atomic write)

**Status:** ready-for-agent

**Tests:** `t/14-redirection/rak/009-json-text.rak`

- [ ] Strict JSON printed is written back as standard JSON.
- [ ] Relaxed JSON (`{ a: 'a' }`, trailing comma) is accepted and normalised.
- [ ] `say @a >a.json` prints a gist that is not JSON, so it fails with a decode error.
- [ ] A statement that prints *and* returns a value is in text mode.
- [ ] Decode failure leaves an existing target byte-for-byte untouched.
- [X] `say 1 >>a.json` fails; the error mentions `.jsonl`. (Done with 05.)
