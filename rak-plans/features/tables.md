# Tables

Status: PLANNED, being built (first slice).

Showing a list of hashes as a grid, as nushell does, and the typed values and commands
that make a nushell-like `ls` possible. Terms: [table](../../GLOSSARY.md#table),
[cell](../../GLOSSARY.md#cell), [filesize](../../GLOSSARY.md#filesize),
[unit literal](../../GLOSSARY.md#unit-literal),
[topical command](../../GLOSSARY.md#topical-command).

```rak
ls                          # a table: name type size modified
ls | sort-by size | drop 2  # topical commands, nushell's names
ls *.md | select name size
ls | get size               # the size column, a list of filesizes
```

Everything here is rak mode only: plain Raku sees no new type, operator or literal.

## Showing a table

irak shows a submission whose value is a table as a grid. In a `.rak` file `say` keeps
Raku's `.gist`; the `table` topical command returns the grid as a `Str`, so
`say ls | table` or `ls | table` at statement level prints it.

```
╭───┬──────────┬──────┬────────┬──────────────╮
│ # │   name   │ type │  size  │   modified   │
├───┼──────────┼──────┼────────┼──────────────┤
│ 0 │ README.md│ file │ 4.4 kB │ 3 days ago   │
│ 1 │ src      │ dir  │ 4.1 kB │ 2 hours ago  │
╰───┴──────────┴──────┴────────┴──────────────╯
```

- Rounded box drawing, a `#` index column, bold green headers (no colour when not on a
  terminal). No footer header: irak [pages](paging.md) long output.
- Columns are the union of the rows' keys, in first-seen order; a missing key is an
  empty cell. Hashes keep their key order in rak mode
  ([ADR 0009](../../docs/adr/0009-rak-hashes-keep-insertion-order.md)).
- A nested list shows as `[3 items]`, a nested hash as `{2 keys}`.
- Wider than the terminal: long cells are cut with `…`, then the rightmost columns are
  dropped and a `…` column added. With no terminal there is no width limit.

### Cells

| Type | Shown as |
|---|---|
| filesize | `1.2 MB` |
| `Duration` | `1min 30sec` |
| `DateTime`, `Instant` | `10 months ago` |
| `Bool` | `true` |
| undefined | empty |

Anything else shows its `.Str`.

## Typed values

- **filesize**: a number of bytes (an `Int`). Shown in metric units with one decimal
  (`1.2 MB`, `878 B`); `kB` is 1000 bytes and `KiB` 1024. `say 1mb` prints `1.0 MB`.
- **`Duration`**: Raku's own. irak and cells show it nushell-style (`1day 3hr 46min
  40sec`); `say` keeps Raku's `.gist`, since that is core.
- **`DateTime`**: Raku's own. `ls` gives `modified` as a `DateTime`.

### Unit literals

`10mb`, `1.5kb`, `1kib`, `90sec`, `2day`: a number touching a unit. Filesize units are
`b kb mb gb tb pb eb` and `kib mib gib tib pib eib`; duration units are
`ns us ms sec min hr day wk`, as in nushell. There is no month or year.

### Arithmetic (second slice)

nushell's rules, checked with nushell 0.117:

| Operation | Result |
|---|---|
| fs ± fs | fs |
| fs × num | fs |
| fs ÷ num | fs |
| fs ÷ fs | num |
| fs mod fs | fs |
| fs ± num | error |
| fs ± dur | error |

`Duration` and `DateTime` keep Raku's core arithmetic (`DateTime - DateTime` is a
`Duration`), which matches nushell except that core accepts `Duration + 5`.

## Topical commands

A [topical command](../../GLOSSARY.md#topical-command) takes the value piped into it,
or `$_` when used alone. A routine becomes one with the `is topical` trait; its last
positional parameter receives the input. Text from an external command arrives as lines
until `from-json` decodes it.

| Command | Does |
|---|---|
| `select a b` | keeps columns `a`, `b`, in that order |
| `reject a b` | removes columns `a`, `b` |
| `drop n` | removes the last `n` rows (default 1) |
| `drop column n` | removes the last `n` columns |
| `sort-by a` | sorts rows by column `a`; `-r` reverses |
| `get a` | the column `a` as a list |
| `table` | the grid as a `Str` |

`where`, `first` and `last` wait: Raku already gives these names a meaning.

## `ls`

A builtin that returns a table, one row per entry, sorted by name. `^ls` still runs
GNU ls.

- Columns `name type size modified`; `type` is `file`, `dir` or `symlink`.
- Arguments: paths and globs; `-a` includes dot files; `-l` adds
  `mode user group target`.

## Settings

The first slice is metric only. A `$*RAK-CONFIG` ordered hash, read like nushell's
`$env.config` (`$*RAK-CONFIG.filesize.unit = 'binary'`), comes with the first option
that needs it.

## Out of scope for now

- `where`, `first`, `last`, `each`, `group-by`.
- `ls -s` and `-d`, `du`.
- Filesize arithmetic (second slice).
