# Hashes keep insertion order in rak mode

In rak mode every hash literal and `%` variable, and every hash that `ls`, `from-json`,
a `.json` load or a [topical command](../../GLOSSARY.md#topical-command) produces, keeps
its keys in insertion order, as nushell's records do. A [table](../../GLOSSARY.md#table)
takes its columns from that order, so `select b a` shows `b` first and `ls` shows
`name type size modified`. The ordered type is a core subclass of `Hash` chosen by rak
mode, so `~~ Hash` keeps working; plain Raku keeps its unordered `Hash`.

## Considered Options

- **Only rak's producers return ordered hashes** (`ls`, `from-json`, loads). Rejected: a
  table typed at the irak prompt as `[{name => …, size => …}]` would show its columns in
  random order.
- **The column order carried by the list** (`@rows but Columns<…>`). Rejected: lost as
  soon as the rows go through `map`.
- **Alphabetical columns.** Rejected: `ls` would show `modified name size type`.
- **Ordered hashes in both frontends.** Rejected: it changes plain Raku, which rak
  features must not leak into.

## Consequences

- Loading a `.json` target keeps the file's key order, which settles that open
  question.
- An ordered hash costs more than a plain one; rak accepts that for interactive data.
