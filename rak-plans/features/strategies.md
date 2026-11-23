# The standard and shell strategies

In [rak mode](../../GLOSSARY.md#rak-mode), every statement or parenthesized group parses in
one of two strategies:

- the [standard strategy](../../GLOSSARY.md#standard-strategy): Raku syntax, plus naked
  strings, dotty subscripts, the new sigils and redirection;
- the [shell strategy](../../GLOSSARY.md#shell-strategy): a command line, in which the first
  word names what to run and the words after it are its arguments.

The strategy is recognized per statement or parenthesized group, so one statement can mix
both. Naked strings, globbing and redirection work in both. The shell strategy takes the
slot that Raku reports as the error "two terms in a row", so no valid Raku program changes
meaning.

Status: the standard strategy is implemented, and so are [commands](commands.md) and
[pipelines](pipelines.md). `alias` is planned.

## Running commands

In the shell strategy, a command runs without spelling out `run`, `shell`, `fork` or
`exec`, as in any Unix shell:

```rak
echo              # runs the command echo, which prints a newline
alias echo=nl     # aliases are supported
say hello world   # calls the say builtin with two naked strings
```

## Parentheses and escapes

```rak
say (1 + 3) things       # prints "4 things": the group is evaluated
say \(1 + 3) things      # prints "(1 + 3) things": the escaped group is text
say \\( 1 + 3 ) things   # prints "\(1 + 3) things"
```

## Pipes: a stage can still be a command

A [pipeline stage](../../GLOSSARY.md#pipeline-stage) is either:

- an **external command** (`ls`, `git log`, `jq`), which reads and writes bytes as in any
  Unix shell, or
- a **rak routine, method or block**, which reads and writes values, with no fork and no
  process.

Both kinds can be mixed in one [pipeline](../../GLOSSARY.md#pipeline). Where a command and a
rak stage meet, data is converted: bytes become lines (or decoded values when a format is
given), and values become text (or are encoded in a format such as JSON or JSONL).

The tendency, though, is to move into the language what used to be a command. jq is the
model. jq is a command, but inside jq, `|` chains filters over JSON values, and a filter
can emit zero, one or many values (`.users[] | .name`). rak supports pipes à la jq as a
language feature: stages pass values, and a stage that emits several values produces a
lazy `Seq` (or a `Supply` when the stream is asynchronous), so pipelines stream instead
of collecting everything first. Raku's feed operators (`==>`) already point in this
direction.

In the shell strategy, `|` is the [pipe](../../GLOSSARY.md#pipe). In the standard strategy
it keeps its Raku meanings, the `any` junction (`1 | 2`) and the slip (`|@a`). Unlike `>`
and `<`, spacing can't separate the two uses, so the strategy decides.

```rak
git log --format=%an | ^sort | ^uniq -c  # all commands: a plain Unix pipe
git log --format=%an | ->unique | ->sort  # a command, then rak methods on lines
<data.json | .users | map *.name;        # jq-like: no process at all
```

So `curl … | jq '.users[].name'` doesn't need jq any more: the language does what the
command did. But nothing forbids keeping jq, or any other command, as a stage. rak takes
on what commands do. It does not exclude the commands themselves.

A pipe is not a [redirection](redirection.md): a redirection attaches one statement's
output or input to a redirection target, while a pipe connects stages.

## The `type` builtin

`type` tells what a name resolves to, as in bash:

```
$ type ls
ls is aliased to `eza -lh --group-directories-first --icons=auto'
$ type eza
eza is /usr/bin/eza
$ type fgit
fgit is a function
fgit ()
{
    git -C "${1:-.}" log --reverse --format=%ai "${2:-HEAD}" | head -1
}
$ type type
type is a shell builtin
```

rak's `type` also reports rak routines, builtins and methods.

## Open questions

- **Name resolution.** When `sort` is both a Raku routine and `/usr/bin/sort`, which one
  wins? Aliases, routines, builtins and `$PATH` commands need one documented lookup order,
  made visible by `type`. Whether rak's own builtins are Raku routines or something else
  is part of this question.
- **Choosing the strategy, and quoting.** scsh, psh, xonsh, Oil/YSH, PowerShell and
  Nushell all ran into these two problems. rak chooses between the strategies per
  statement or parenthesized group, with explicit escapes (`\(`). This is the area to
  test most thoroughly.
- **Calling a routine with no arguments.** A bare word that names a known routine calls
  it; a word that names nothing known is a naked string. Whether a routine *must* be
  called with parentheses in the shell strategy, to tell it from a command, is undecided.
