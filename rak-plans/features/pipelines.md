# Pipelines

Status: WIP.

[Pipelines](../../GLOSSARY.md#pipeline) in rak and irak: Unix pipes between
[commands](commands.md), and pipes à la jq between rak stages, mixed freely. The
background is in [strategies](strategies.md#pipes-a-stage-can-still-be-a-command).

```rak
git log --format=%an | ^sort | ^uniq -c    # all commands: a plain Unix pipe
git log --format=%an | ->unique            # a command, then a rak method on its lines
<data.json | .users | map *.name;          # jq-like: no process at all
```

## When `|` is a pipe

A statement is a pipeline when its first stage is a command, a
[load](../../GLOSSARY.md#load) (`<file`) or a leading dotty subscript (`.users`, `.[]`),
and a spaced `|` follows on the same line.

Planned: a spaced `|` is also a pipe when the word after it can start a stage: a
`^cmd`, an external command, `->meth`, a topical command, `from-…`/`to-…` or a block.
So `@names | ^sort` pipes, while `1 | 2` stays the `any` junction, since `2` starts no
stage. A junction with a command word on the right is written `$x | foo()` or
`any($x, foo)`. Today a variable does not start a pipeline: write
`$_ = @names; .[] | ^sort`. Everywhere else `|` keeps its Raku meanings, and `|@a` is
a slip.

Planned: a pipeline continues on the next line when the line ends with `|`, or when
the next line starts with `|`:

```rak
ls
  | sort-by size -r
  | select name size
```

A pipeline also works inside parentheses, where its value is used:
`my @u = (<data.json | .users)`.

## Stages

A [stage](../../GLOSSARY.md#pipeline-stage) receives the whole upstream value, as with
Raku's `==>`, not one value at a time as in jq. Per-value work is explicit, through
`map` or `.[]`.

| Stage              | How the input is passed in                      |
|--------------------|-------------------------------------------------|
| external command   | on its standard input                           |
| `->meth args`      | `input.meth(args)`                              |
| `.path` (dotty)    | `input.path`                                    |
| `{ block }`        | `$_ = input`                                    |
| `name args`        | `name(args, input)`: input last, as with `==>`  |
| `from-json`        | decodes the input as one JSON document          |
| `from-jsonl`       | decodes the input as JSON Lines, a `Seq`        |
| `.`                | shows the input as JSON ([formatter](formatter.md)) |

## Where commands meet rak stages

- **Command → rak stage:** the command's output becomes a lazy `Seq` of lines, newlines
  removed. Decode it with a `from-json` or `from-jsonl` stage.
- **Rak stage → command:** a `Str` or a number is written as one line; a list or a `Seq`
  one element per line; a hash, or a hash or list inside a list, as a JSON Lines record.
  Planned: the [command catalog](command-catalog.md) picks the encoding instead, see
  below.
- **Command → command:** a real OS pipe; the commands run at the same time.

## Encoding a value for a command (planned)

Values pass between rak stages as values, and bytes between commands as bytes; only
where the two meet is there an encoding to pick. For a rak stage feeding a command:

- An explicit `to-yaml`, `to-json` or `to-jsonl` stage always wins.
- A `Str`, a number or a flat list stays as lines, so `ls | get name | ^grep md` works.
  A filesize in it is its number of bytes, a `Duration` its nanoseconds, a `DateTime`
  RFC 3339.
- A hash, or a list holding a hash or a list, is [YAML](yaml.md) with nushell's tags:
  one document holding a block sequence, written item by item so a lazy `Seq` stays
  lazy.
- When the [command catalog](command-catalog.md) says the command does not read YAML,
  rak picks the first format it does read among `jsonl` and `json`; `json` gets a
  whole list as one array. `ls | ^jq .name` works this way.

A table goes to a command as data, not as the grid nushell sends: `ls | table | ^less`
pipes the grid's text.

Text from a command stays lines until a `from-yaml`, `from-json` or `from-jsonl` stage
decodes it, unless the catalog says the command emits a format: then the next rak stage
gets the decoded value, and a `to-text` stage gives the raw text back. Rak
never guesses a format from the text. The full rule is in the
[catalog](command-catalog.md#choosing-a-format).

## Value and output

At statement level, a final command writes to the terminal. When the pipeline's value is
used, a final command's output is captured as a `Str`, as for a lone command; a final
rak stage's value is the pipeline's value, made whole (a lazy `Seq` is read to the end).

## Exit status

`$?` is the first command that failed, else the last (bash's `pipefail`). `@?` holds
the `Proc` of every command of the last pipeline, in order, like bash's `PIPESTATUS`; a
lone command sets it to one element. A pipeline without commands changes neither.

A command whose reader went away gets SIGPIPE, as in a shell: `yes | head -2` and
`^yes | ->head(2)` end. SIGPIPE in a command that is not the last is not a failure.

## Out of scope for now

- `Supply` stages for asynchronous streams (`tail -f`); lazy line reading covers most
  of it.
- A pipeline failure failing a `.rak` file; it follows commands'
  [ticket 02](../../.scratch/commands/issues/02-nonzero-exit-fails-file.md).

## Implementation notes

- Grammar and actions in `src/Rak/*` only: `rak-pipeline` and `rak-stage`. While a
  pipeline is parsed, `$*RAK-PIPE` is set, and `infix:<|>` refuses a spaced `|` so that
  `EXPR` stages stop at the pipe. Blocks and parentheses reset it.
- Each stage becomes an expression around the previous one; `RAK-PIPE-END` wraps the
  whole and waits for the commands. Runtime in
  `src/core.c/Rakudo/Internals/RakFormat.rakumod`.
- A piped command is not waited for: its `Proc` is the stage's value. A command fed by
  another binds its standard input to the upstream's output pipe.
- Rakudo keeps its copy of a pipe's read end open, so a writer would never see its reader
  exit. When a command reading from a command exits, or a rak stage stops reading, the
  writer is sent SIGPIPE.
- Tests: `t/16-pipelines/rak/`.
