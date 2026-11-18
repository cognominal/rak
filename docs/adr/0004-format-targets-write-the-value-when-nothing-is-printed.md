# A target with a format gets the statement's value when nothing is printed

Output redirection still binds standard output for one statement, as
`docs/adr/0002-redirection-binds-the-statement-stream.md` says. The target's extension
can now select a format (`.json`, `.jsonl`), and for such a target one exception applies:
if the statement printed nothing, its value is encoded in the format and written. So
`@a >a.json` writes `@a` as JSON. If the statement did print, that text is the content
(`print "{ a: 'a' }" >a.json`): it must decode in the format and is written re-encoded in
standard form. We chose this so a data file can be written without spelling out the
encoding, while `print` and `say` still mean what 0002 says.

## Considered Options

- **The value always wins for a format target.** Rejected: `print "..." >a.json` would
  throw away what the statement printed, which contradicts 0002 in exactly the case where
  the user wrote output on purpose.
- **Never write values; require `to-json @a >a.json`.** Rejected: data files are the main
  reason to have formats, and spelling out the encoder repeats what the extension already
  says.

## Consequences

- This narrows 0002's rule that "a statement that produces no output writes nothing". The
  rule still holds for targets with no format: `$x >f.txt` leaves an empty file.
- Whether output was printed is only known after the statement runs, so for a format
  target the printed text is collected in memory, checked, and written through a temporary
  file that replaces the target only on success. A failed encode or decode leaves the old
  file untouched. Plain-text targets still stream as they go.
- A statement that both prints and returns a value is in text mode; its value is dropped.
- The same "printed or not" test already decides the irak topic, so the two features agree
  on what counts as producing output.
- `>>` to a `.json` target is an error (appending does not produce valid JSON); `.jsonl` is
  the format that supports appending, one record per line.
