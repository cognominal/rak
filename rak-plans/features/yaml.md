# YAML

Status: WIP. Loads, targets, `>>` and `from-yaml` work. Not built yet: YAML on pipes
to commands ([Pipelines](pipelines.md#encoding-a-value-for-a-command-planned)) and the
YAML literals of [myaml](#myaml).

YAML as a [format](../../GLOSSARY.md#format), next to JSON: loads and targets with a
`.yaml` or `.yml` extension, and the `from-yaml` pipeline stage. Unlike JSON, YAML can
say what type a value has, with a [tag](../../GLOSSARY.md#tag), so a filesize, a
`Duration` or a `DateTime` survives a round trip without `into`.

```rak
ls >files.yaml               # sizes as !filesize, dates as !!timestamp
my @files <files.yaml        # back as filesizes and DateTimes
cat files.yaml | from-yaml | select name size
```

## Nushell's conventions, Raku's types

The files follow nushell's conventions, checked with nushell 0.117, so a file written by
nushell's `to yaml` loads in rak with the same types, and the other way round. In
memory, each tag becomes the closest Raku type. This is the rule JSON already follows
in [Tables](tables.md#converting): nushell's encoding on the wire, Raku types inside.

| YAML | Raku type |
|---|---|
| `!filesize` | filesize |
| `!duration` | `Duration` |
| `!!timestamp` | `DateTime` |
| `!range` | `Range`, `Seq` |
| `!!binary` | `Blob` |
| `!glob` | `Str` |
| `!cell-path` | `Str` |
| int | `Int` |
| float | `Rat`, `Num` |
| mapping | ordered hash |
| sequence | `Array` |
| `null` | `Any` |

- A `!filesize` value is a number of bytes and a `!duration` value a number of
  nanoseconds, the numbers JSON encoding already uses. `!filesize 1.5kb` is an error,
  as in nushell.
- A `!range` is spelled as in nushell: `1..3`, `1..<3`, `1..`. A stepped one,
  `1..2..9`, loads as the `Seq` `1, 3 ... 9`: a Raku `Range` has no step.
- A float loads as the JSON decoder does: `1.5` is a `Rat`, `1.5e3` a `Num`.
- A mapping keeps its key order
  ([ADR 0009](../../docs/adr/0009-rak-hashes-keep-insertion-order.md)).
- `>>f.yaml` appends a document, after a `---` when the file is not empty, so the file
  then loads as a list of documents.
- A `.yml` target is a `.yaml` one; case is ignored. A [URL](url-targets.md) load
  decodes YAML when the server declares `application/yaml`, `application/x-yaml` or
  `text/yaml`.
- `!glob` and `!cell-path` load as strings, so a nushell file never fails over one
  cell. A glob gets its own type once rak has one; rak has no value for a cell path.

## Untagged scalars

Untagged scalars follow YAML 1.2's core schema, nushell's default: `true`, `null`,
numbers, and everything else a string. `2026-01-02T03:04:05Z` stays a string; only
`!!timestamp` makes a date.

## Unknown tags

A tag rak does not know, such as `!foo 1` or a typo, is an error, as in nushell.
`from-yaml --ignore-tags` loads the untagged value instead. A load such as
`my %h <f.yaml` takes no flags; ignoring tags there goes through
`cat f.yaml | from-yaml --ignore-tags`.

## How much YAML

- Block and flow collections, every scalar style, `|` and `>` blocks, comments.
- Anchors and aliases (`&x`, `*x`). Merge keys (`<<: *x`) are not supported: YAML 1.2
  dropped them and nushell rejects them.
- A stream of several documents, separated by `---`, loads as a list of documents; a
  single document loads as itself, as nushell's `--multiple auto` does.
- `%TAG` directives and complex keys (`? key`) are an error that names the feature.

## Writing

Written YAML is nushell's: block style, a filesize as `!filesize 1500`, a
`Duration` as `!duration 90000000000`, a `DateTime` as `!!timestamp` in RFC 3339, a
multi-line string as a `|-` block, a `Range` as `!range`.

Raku types nushell has no tag for are widened to the nearest nushell type, so rak's
output always loads in nushell:

| Raku type | Written as |
|---|---|
| `Date` | `!!timestamp` |
| `Instant` | `!!timestamp` |
| `Set` | sequence |
| `Bag` | mapping |
| `Pair` | mapping |
| `Rat` | float |

- A `Date` is written as midnight UTC, as nushell writes `2026-01-02`.
- A `Bag` maps each item to its count; a `Pair` is a one-key mapping.
- A `Rat` loses precision, as in JSON.
- An `Int` range with an excluded start moves its start: `1^..3` is `!range 2..3`;
  `1..*` is `!range 1..`. A range of strings is a sequence of its items; an infinite
  one is an error.
- A `Seq` is a sequence: `1, 3 ... 9` does not remember its step, so it cannot be
  written back as a stepped `!range`.
- Exact rak-only tags (`!rak/date`, `!rak/set`) may come later, as an option.

## Loader

Rak has its own loader and writer, in the CORE setting beside the JSON decoder: a
`.yaml` load is a core feature, and core cannot depend on an ecosystem module. The
YAMLish module (0.1.3) was considered: it drops tags it was given callbacks for, loses
key order and cannot write a `DateTime`. A fix for its tags may go upstream separately.

## Errors

A YAML error has the JSON error's shape, and the same exception class:

```
f.yaml: invalid YAML at line 3, column 7: <reason>
f.yaml: unknown tag !foo at line 3, column 4 (from-yaml --ignore-tags loads it untagged)
```

The source is the file, the URL, or `from-yaml` for a pipeline stage. A YAML literal in
a `.rak` file fails at compile time, at its line in the file.

## myaml

[myaml](myaml.md) is a mode of this loader, still to be specified: the same parser, the
same tags and the same schema, with `$x` and `$$x` meaningful only in that mode. The
YAML literals of `::=` and `q:to<END>:yaml` are plain YAML and go through the loader at
compile time, so `size: !filesize 1500` in a literal is a filesize.
