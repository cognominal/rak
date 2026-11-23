# The formatter

A lone `.` is the [formatter](../../GLOSSARY.md#formatter): a pipeline stage that shows
its input as indented JSON, as `jq .` does. Until now a lone `.` was a syntax error
("Malformed postfix call"), so the spelling takes nothing away from rak.

```raku
<api.github.com/users/octocat     # in irak: load into the topic
.                                 # show the topic as JSON
^curl -s https://example.com/x.json | .
```

## Decisions

- **Input.** Piped into, `.` formats what comes in. Used alone, its input is the topic
  `$_`.
- **Values.** Values encode as they do for a `.json` redirection target (`>a.json`): a
  Hash is an object, a lone Pair is an error.
- **Strings.** A Str is read as JSON first, then as rak data literals; if neither
  parses, it is encoded as a JSON string literal. Rak data literals are parsed, never
  run: numbers, quoted strings, `True`, `False`, `Nil`, naked strings, pairs (`:a`,
  `:!a`, `:a(1)`, `:a<x>`, `a => 1`), word lists `<a b c>`, and `( )`, `[ ]`, `{ }`.
  Anything else (variables, calls, operators) is not data. Reading a Str with `EVAL` was
  rejected: the Str is often a server's response.
- **Streams.** Text input is a stream of concatenated JSON values, so JSONL and
  `{"a":1}{"b":2}` show as several documents. A Seq from a rak stage shows each value as
  its own document; to get one array, write `[…] | .`.
- **Printing or returning.** At statement level `.` prints, as an external command does,
  so the [irak topic](../../GLOSSARY.md#irak-topic) stays the value being looked at. When
  its value is used (`my $s = .`, `. >x.json`) it returns the JSON text, uncolored.
- **JSON loads in irak.** A submission whose value is what a load just decoded from
  JSON (`<api.github.com/…` answering JSON, `<a.json`) shows that value as `.` would,
  colors included, and it still becomes the topic. A load into a variable
  (`my %h <a.json`) and a load without a format show as before.
- **Colors.** Only on a terminal, with `jq`'s default palette (keys blue, strings green,
  null gray). No setting until someone asks for one.
- **Layout.** Indented by 2, like the `.json` encoder. Keys of a Hash are sorted; keys of
  JSON text keep their source order.

## Limits

- Like any rak stage, `.` at the end of a pipeline takes no redirection:
  `cmd | . >f.json` does not parse; write `(cmd | .) >f.json`.
- A newline does not end a statement, as in Raku: `.` followed by a line starting
  with `.a` reads as a method call on the formatter's value. End it with `;`.

## Open questions

- **Key order on load.** `my %h <in.json` loses the file's key order, so writing it back
  sorts the keys. Keeping the order needs an ordered hash on load.
