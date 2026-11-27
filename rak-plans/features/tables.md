# Tables

Status: WIP. The grid, `ls`, the topical commands, `into`, the settings and
the JSON encoding work; [Not built yet](#not-built-yet) lists the rest.

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
- When `$*OUT` is a terminal, in irak or in a `.rak` file, the grid fits its width:
  long cells are cut with `…`, then the rightmost columns are dropped and a `…` column
  added. Redirected or piped, there is no width limit and no colour. `table -w 120`
  sets the width, as in nushell. The width is measured when the grid is rendered.

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
or `$_` when used alone. A routine becomes one with the `is topical` trait (planned):

```rak
sub top($n = 10) is topical { sort-by size -r | first $n }
ls | top 5
```

- A call in command position passes the piped value, else the call site's `$_`. This
  is decided at compile time: `$_` is not dynamic, so a routine cannot read its
  caller's.
  Inside a `for`, `given` or `map` that is the item; inside a plain `sub`, its own
  `$_`. An undefined `$_` is an error naming the command:
  `select: no input (nothing piped, and $_ is undefined)`.
- The trait adds a hidden named parameter and binds the body's `$_` to it: the routine
  needs no special signature, and topical commands inside its body get the input.
- Called outside command position, the input is passed explicitly:
  `top(5, :topic(@rows))`.
- Text from an external command arrives as lines until a `from-…` stage decodes it,
  unless the routine declares it reads a format: `is reads<yaml>`
  ([command catalog](command-catalog.md#traits-for-rak-routines)) decodes YAML and
  JSON.

The builtins below are wired into the compiler today; with the trait they become
routines of the setting declared `is topical`.

| Command | Does |
|---|---|
| `select a b` | keeps columns `a`, `b`, in that order |
| `reject a b` | removes columns `a`, `b` |
| `drop n` | removes the last `n` rows (default 1) |
| `drop column n` | removes the last `n` columns |
| `sort-by a` | sorts rows by column `a`; `-r` reverses |
| `get a` | the column `a` as a list |
| `table` | the grid as a `Str` |
| `into filesize` | converts, see [Converting](#converting) |
| `into duration` | idem |
| `into datetime` | idem |

`where`, `first` and `last` wait: Raku already gives these names a meaning.

## `ls`

A builtin that returns a table, one row per entry, sorted by name. `^ls` still runs
GNU ls.

- Columns `name type size modified`; `type` is `file`, `dir` or `symlink`.
- Arguments: paths and globs; `-a` includes dot files; `-l` adds
  `mode user group target`.

## Settings

`$*RAK-CONFIG` is an ordered hash holding nushell's `$env.config` names, filled with the
defaults. The [startup file](startup-file.md) `init.rak` plays the part of nushell's
`config.nu`; a `.rak` file gets the defaults and may set `$*RAK-CONFIG` itself, as a
nushell script does not read `config.nu`.

```rak
$*RAK-CONFIG.table.mode = 'light';
$*RAK-CONFIG.color_config.header = 'green_bold';
$*RAK-CONFIG.filesize.unit = 'binary';
```

| Key | Default |
|---|---|
| `table.mode` | `rounded` |
| `table.index_mode` | `always` |
| `color_config.header` | `green_bold` |
| `color_config.row_index` | `green_bold` |
| `color_config.<type>` | none |
| `filesize.unit` | `metric` |
| `filesize.precision` | `1` |
| `datetime_format.table` | humanized |
| `datetime_format.normal` | humanized |

- `table.mode` is `rounded`, `light`, `compact`, `ascii` or `none`;
  `table.index_mode` is `always`, `never` or `auto`.
- `filesize.unit` is `metric`, `binary` or a unit such as `kB` or `MiB`. A
  `datetime_format` is a strftime format.

- `<type>` is `filesize`, `duration`, `datetime`, `bool`, `int`, `float`, `string`
  or `nothing`.
- A colour is spelled as in nushell: `green_bold`, `light_cyan`, `{fg: '#ff0000',
  attr: 'b'}`.
- `table.index_mode` `auto` shows `#` unless the rows have an `index` key.
- An unknown key is kept and ignored, so a copied nushell config does no harm.
- A later `config` command may open `init.rak` in `$EDITOR`, as nushell's `config nu`.

## Converting

JSON has no filesize, duration or date, so `from-json` and `.json` loads keep strings as
strings, as nushell's `from json` does. The `into` topical commands convert, a value or,
given column names, those cells of a table:

```rak
<api.github.com/repos/rakudo/rakudo/releases | into datetime published_at created_at
$_ = '1.2 MB'; into filesize                # 1200000 bytes
$_ = '1min 30sec'; into duration
```

A string literal cannot start a pipeline (only a command, a load or a leading dot can),
so a lone value goes through `$_`.

- `into filesize` reads a number (bytes) or a unit literal, spaced or not: `1.2 MB`,
  `1kib`.
- `into duration` reads a number (nanoseconds, as nushell) or unit literals, spaced or
  not: `1min 30sec`, `90sec`.
- `into datetime` reads ISO 8601 / RFC 3339, or a number of seconds since the epoch.

Encoding to JSON follows nushell's `to json`: a filesize is its number of bytes, a
`Duration` its number of nanoseconds, a `DateTime` an RFC 3339 string.

## Not built yet

- Ordered hash literals and `%` variables
  ([ADR 0009](../../docs/adr/0009-rak-hashes-keep-insertion-order.md)): only `ls`,
  the topical commands and `$*RAK-CONFIG` make ordered hashes so far. A plain hash's
  columns come sorted.
- Unit literals (`10mb`, `90sec`), hence `say 1mb`.
- The `is topical` trait: the topical commands are builtins only.
- Filesize arithmetic (second slice).

Notes on what is built:

- A topical command or `ls` is a command only in command position: `say get name`
  calls Raku's `get`; write `say (get name)`.
- Redirected to a target without a format, `ls` runs GNU ls (`ls > out`): a table
  has no text form for files yet. `ls >files.yaml` and `ls >files.json` write the table.
- `ls` and the topical commands are found before setting routines of the same name
  (`get`), but after routines the program declares.

## Out of scope for now

- `where`, `first`, `last`, `each`, `group-by`.
- `ls -s` and `-d`, `du`.
- Filesize arithmetic (second slice).
