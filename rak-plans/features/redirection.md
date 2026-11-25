# Redirection

A [redirection](../../GLOSSARY.md#redirection) attaches one statement's output or input to
a file. The operator touches its [target](../../GLOSSARY.md#redirection-target); with a
space after it, it is an ordinary Raku operator (see [spacing](spacing.md)).
A `<…>` at the start of a statement, closed on the same line by a `>` that touches its
last word and is not followed by a filename, stays a word list: `[<a b>]`,
`<x y>->map(…)`.

Status: WIP, NEEDSPEC — implemented for `STMT >file`, `STMT >>file`, `<file STMT`, the
[load](../../GLOSSARY.md#load) `LVALUE <file`, and the `.json` and `.jsonl`
[formats](../../GLOSSARY.md#format). The planned targets and operators are directions,
not a complete spec. Usage is in the
[cheat sheet](../../rak-docs/CHEATSHEET.md#redirection). The design decisions are recorded in:

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
`<in.txt STMT >out.txt` is the only combination today. rak takes the shell's way:
**repeated redirection tokens, processed left to right**. Colon pairs
(`STMT :out>out.txt :err>err.txt`) were considered: easier to parse and more Raku-like,
but less shell-like, and they say again what the operator already says.

Suggested order: a load followed by output redirection (below), then `2>` and `2>>`,
then `2>&1` and `&>`.

### A load followed by output redirection

Status: SPEC, not implemented. Today `<url >file` dies with "Input redirection from a
URL is not supported", and `my $x <src >file` does not parse; write
`my $x <src; $x >file` instead.

```rak
my $x <api.github.com/repos/cognominal/rak >rak.json   # GET, assign $x, write rak.json
<api.github.com/repos/cognominal/rak >rak.json         # the same, into the topic $_
my @r <log.jsonl >>all.jsonl                           # load a file, append its records
```

- **Forms.** Both loads take one trailing output redirection: `LVALUE <src >dst` and
  `<src >dst`. The source is any load target, file or URL, bare host included.
- **Meaning.** The load runs first; the output redirection then gets the statement's
  value, which is the loaded value. A load prints nothing, so this is
  [value mode](../../GLOSSARY.md#value-mode) (ADR 0004): `>rak.json` writes the decoded
  value encoded again as JSON, not the server's bytes. The raw response is still in
  `@*IWEB[*-1].body` in irak. No `tee`-like byte copy is planned.
- **Operators.** `>` and `>>` follow ADR 0004 (`>>` to `.json` is an error, to `.jsonl`
  appends). `>url` POSTs the loaded value, as `STMT >url` does; the statement's value is
  then the response (ADR 0005), and the left-hand side still holds the loaded value.
- **Order.** Only `<src >dst`. `>dst <src` is a syntax error: the output side keeps
  its place at the end, where `2>` will join it.
- **Spacing.** Each operator touches its target; whitespace between the two
  redirections is free.
- **Plain-text target.** Open: with no format, value mode does not apply, and ADR 0002
  leaves the file empty. `my $x <notes.txt >copy.txt` should probably write the text
  loaded, which is a `Str`; a non-`Str` value (decoded JSON) to a plain-text target
  should be an error rather than an empty file.
