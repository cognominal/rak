# The command catalog

Status: PLANNED.

The [command catalog](../../GLOSSARY.md#command-catalog) records what formats
[external commands](../../GLOSSARY.md#external-command) read and emit, so a
[pipeline](pipelines.md) can hand each one data it understands: [YAML](yaml.md) by
default, JSON to a command that reads only JSON. Rak routines declare the same
[capabilities](../../GLOSSARY.md#capability) with traits.

```rak
ls | ^jq .name           # jq reads JSON, so rak sends JSON Lines
ls | ^yq .               # yq reads YAML
ls | ^grep md            # no entry: YAML for a table, lines for a flat list
```

## Capabilities

A capability says that a command **reads** a format on its standard input, or
**emits** one on its standard output.

| Format | Is |
|---|---|
| `lines` | a string per line |
| `json` | one document |
| `jsonl` | JSON Lines |
| `yaml` | YAML |
| `text` | one string |

- YAML 1.2 is a superset of JSON: whatever reads `yaml` reads `json`, and the YAML
  decoder decodes `json` output.
- `jsonl` stays apart: several JSON documents, one per line, are not valid YAML.
- A command without an entry reads `lines`, and YAML for structured values
  ([Pipelines](pipelines.md#encoding-a-value-for-a-command-planned)); it emits `lines`.

## Where the catalog lives

Rak ships defaults in the CORE setting. A user's `commands.yaml` in rak's config folder
([ADR 0006](../../docs/adr/0006-rak-user-files-follow-xdg-on-every-platform.md)) is
merged over them, and the result is `$*RAK-CONFIG.commands`, which `init.rak` may also
change. A user's entry replaces the shipped one of the same name.

```yaml
jq:
  reads: [jsonl, json]
  emits: json
  flags: {-r: {emits: lines}, -c: {emits: jsonl}}
yq: {reads: [yaml], emits: yaml}
gh api: {emits: json}
```

- A key of several words, such as `gh api`, matches a command and its subcommand.
- The shipped entries cover `jq`, `yq`, `gh api`, `kubectl` and a few more.

## Flags

An entry's `flags` change its capabilities when the command is given them: an exact
flag (`-r`), or a flag and its value (`-o json`).

```yaml
kubectl get:
  flags: {-o json: {emits: json}, -o yaml: {emits: yaml}}
jq:
  bundling: true
  flags: {-r: {emits: lines}, -c: {emits: jsonl}}
```

- `--output=yaml` matches as `--output yaml`.
- Bundled short flags (`-rc`) are split into `-r -c` only for an entry that says
  `bundling: true`: `find -name` is not `-n -a -m -e`.

## Traits for rak routines

A rak routine returns values, so it declares only what it reads: `is reads<yaml>`
decodes text piped into it, and other values pass untouched. The builtin table
commands are `is reads<yaml>`, so `cat f.yaml | select name` works. A routine that gets
text in a format decodes it and returns the value; there is no *emits* trait.

## Choosing a format

On a rak stage feeding a command:

1. An explicit `to-yaml`, `to-json` or `to-jsonl` stage wins.
2. A `Str`, a number or a flat list goes as `lines` when the command reads them, as a
   command without an entry does.
3. A structured value goes as `yaml` when the command reads it, else `jsonl`, else
   `json`.
4. A flat value to a command reading only `json` or `jsonl` is encoded as JSON: a `Str`
   is a JSON string, a list an array, or one value per line for `jsonl`.
5. When no format fits, such as a table to a command reading only `lines`, it is an
   error naming the command and the formats it reads.

## Decoding a command's output

When the catalog says a command emits `json`, `jsonl` or `yaml`, a rak stage after it
gets the decoded value:

```rak
gh api repos/rakudo/rakudo | .stargazers_count
```

- A command without an entry gives lines, as before; rak never guesses from the text.
- `cat` with one file argument emits the format of its extension
  ([Pipelines](pipelines.md#where-commands-meet-rak-stages)).
- Between two commands, bytes pass untouched.
- The raw text comes back with a `to-text` stage, which joins the lines:
  `gh api repos/rakudo/rakudo | to-text`. `^cmd` keeps its one meaning, the external
  command rather than a builtin or routine of that name, and still uses the catalog.

## TBD: commands whose flags pick the format

`gh` shows that one entry per command is not enough. `gh api` emits JSON, but most of
`gh` prints text for a human unless given a flag:

- `--json fields` emits JSON (`gh repo view`, `repo list`, `pr list`, `issue list`…).
- `-q`/`--jq expr` filters that JSON with jq, so it emits what jq prints, often lines.
- `-t`/`--template string` formats it with a Go template, so it emits text.
- `gh api -i` prints the HTTP headers before the body, so it emits text.

The flag rules above cannot say this yet. Three proposals, not settled:

- A flag with any value: `--json *` matches `--json name,url` and `--json=name`.
- Several flags given (`--json name --jq .name`): the flag that comes later in the
  entry wins, so `--jq` and `--template` are listed after `--json`.
- Both `gh` and `gh api` match `gh api …`: only the entry with the most words applies;
  it replaces the shorter one rather than merging with it.

With them, a single `gh` entry would cover the subcommands:

```yaml
gh:
  flags: {--json *: {emits: json}, -q *: {emits: lines}, --jq *: {emits: lines},
          -t *: {emits: text}, --template *: {emits: text}}
gh api:
  emits: json
  flags: {-q *: {emits: lines}, --jq *: {emits: lines}, -t *: {emits: text},
          --template *: {emits: text}, -i: {emits: text}, --include: {emits: text}}
```
