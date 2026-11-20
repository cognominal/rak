# Redirection

A [redirection](../../GLOSSARY.md#redirection) attaches one statement's output or input to
a file. The operator touches its [target](../../GLOSSARY.md#redirection-target); with a
space after it, it is an ordinary Raku operator (see [spacing](spacing.md)).

Status: implemented for `STMT >file`, `STMT >>file`, `<file STMT`, the
[load](../../GLOSSARY.md#load) `LVALUE <file`, and the `.json` and `.jsonl`
[formats](../../GLOSSARY.md#format). Usage is in the
[cheat sheet](../../CHEATSHEET.md#redirection). The design decisions are recorded in:

- [ADR 0002](../../docs/adr/0002-redirection-binds-the-statement-stream.md): a
  redirection binds `$*OUT` or `$*IN` for one statement; it does not rewrite the call.
- [ADR 0004](../../docs/adr/0004-format-targets-write-the-value-when-nothing-is-printed.md):
  a target with a format gets the statement's value when nothing is printed
  ([value mode](../../GLOSSARY.md#value-mode)), and the printed text otherwise
  ([text mode](../../GLOSSARY.md#text-mode)).

This document covers what is planned.

## Redirection on values, not only bytes

In Unix a redirection moves bytes, and every program parses them again. In rak the
target's extension picks a format: `@a >a.json` encodes the value as JSON, the load
`my %h <h.json` decodes it, and `.jsonl` holds one record per line. Inside the language,
data stays typed. At the file system boundary it is encoded in a format. McIlroy's "text
is the universal interface" still holds at the edges, and structure holds inside.

## Planned targets

- **Subscripted targets**: `>@files[0]`, `>%config<output>`, and with dotty subscripts
  `>%config.output`. Today a target is a single naked string, quoted string or `$`
  variable.
- **More formats**: YAML and TOML (`$struct <file.toml`), and [myaml](myaml.md) for
  pattern matching.

## Planned operators

The shell operators below have no rak form yet. Each runs into an existing Raku meaning.

| Shell | Proposed rak form | Difficulty |
|---|---|---|
| `2>file`, `2>>file` | `STMT 2>file` | `2` is already a term. The grammar must read a digit touching `>` as a file descriptor. Needs a per-statement `$*ERR` binding. |
| `2>&1`, `1>&2` | `STMT 2>&1` | Needs the `N>` form above. The binding itself is easy: `temp $*ERR = $*OUT`. |
| `&>file` | `STMT &>file` | `&` is an infix, but `&>` touching a target is unclaimed. Binds both `$*OUT` and `$*ERR`. |
| `<>file` | `STMT <>file` | `<>` is the empty angle-bracket quote. Probably needs another spelling. |
| `<<EOF` | `STMT <<EOF` | `<<` is a hyperoperator and part of `«»` quoting. Needs careful lexing. |
| `<<<word` | `STMT <<<word` | Same problems as `<<EOF`, without a terminator. |
| `N<&M` | — | Needs file-descriptor prefixes on both `<` and `>`. |

## Stacking

A shell command can carry several redirections: `cmd <in.txt >out.txt 2>err.txt`. rak
accepts one redirection at the end of a statement and one at the start, so
`<in.txt STMT >out.txt` is the only combination today. Options for more:

- **Repeated redirection tokens** after the statement, processed in order. Closest to
  the shell, and needs the `N>` form to say which stream.
- **Colon pairs**: `STMT :out>out.txt :err>err.txt`. Easier to parse, more Raku-like,
  less shell-like.

Suggested order: `<` with `>` together, then `2>` and `2>>`, then `2>&1` and `&>`.
