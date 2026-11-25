# Commands

Status: WIP.

Running [commands](../../GLOSSARY.md#command) in rak and irak, through the
[shell strategy](../../GLOSSARY.md#shell-strategy). Commands joined by pipes are
[pipelines](pipelines.md).

## What runs

A command is an [alias](aliases.md), a rak routine, a builtin, or an
[external command](../../GLOSSARY.md#external-command) found on `$PATH`, looked up in
that order.

```rak
say hello world      # rak routine, two arguments
ls -l                # external command
ls                   # a lone word naming a $PATH program runs it, at statement level
my $x = ls           # not at statement level: the naked string 'ls'
^sort data.txt       # force the external command over the rak routine `sort`
```

A rak name wins over an external command of the same name; `^name` forces the external
one. Setting routines are rak names too, so `sort` and `run` are rak's unless written
`^sort`, `^run`.

## Arguments

Arguments parse like a Raku `<<…>>` list: whitespace separates words, quotes group, `$x`
and `{…}` interpolate. `$x` is never word-split; a list variable gives one argument per
element. A leading `/` starts a naked path and `m/` a regex (matched against `$_`); a
relative path starting with `m/` is written `./m/…`.

```rak
my @f = <a.txt b.txt>;
ls -l @f "my file" {1+1}    # ls -l a.txt b.txt 'my file' 2
```

## Output

At statement level an external command writes straight to the terminal (so `vim` and
`less` work) and its value is its `Proc`, which prints nothing: in irak, `$_` is unchanged.
When its value is used, as in `my $out = (ls)`, its standard output is captured as a `Str`.

## Exit status

`$?` holds the last [exit status](../../GLOSSARY.md#exit-status) as a `Proc`, per routine
like `$!`. It numifies to the exit code: `$? == 0`, `$?->exitcode`, `$?->signal`. A rak
routine run as a command leaves `$?` unchanged.

A non-zero exit status fails a `.rak` file, like `run` in sink context. irak only shows a
dimmed `exit N`.

## Redirection

The [redirection](../../GLOSSARY.md#redirection) operators act on the child's file
descriptors, written touching their target:

| Spelling     | Effect                         |
|--------------|--------------------------------|
| `ls >out`    | standard output to `out`       |
| `ls >>log`   | appended to `log`              |
| `sort <in`   | standard input from `in`       |
| `make 2>err` | standard error to `err`        |
| `make 2>&1`  | standard error to standard out |

A spaced `>` after a command is a compile error that suggests `>target`.

## Builtins

- `type name` lists every meaning of `name`, its alias and rak first, in bash's wording (`ls is
  /usr/bin/ls`, `say is a rak routine`), marking the one that wins. It returns that list.
- `cd dir` changes `$*CWD` and the process directory; `cd` alone goes to `$*HOME`, `cd -`
  to the previous directory. It is not scoped.

## Out of scope for now

Globbing, environment assignments (`FOO=1 cmd`), `pushd` and `popd`.

## Implementation notes

- Grammar and actions in `src/Rak/*` only; plain Raku is unchanged.
- The shell strategy takes the "two terms in a row" slot; a lone word becomes a command
  when it names a `$PATH` program at compile time: when a `.rak` file is compiled, and
  in irak when each submission is compiled.
- The program to run is looked up on `$PATH` again when the statement runs.
- Known deviations from this spec are tickets in `.scratch/commands/issues/`.
- Running, `$?`, `cd` and `type` live in a rak-only runtime module.
