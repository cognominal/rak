# rak and the Perl Power Tools

The [Perl Power Tools](perl.md#perl--from-duct-tape-to-solipsism) and rak ask
the same question: how should the Unix toolbox relate to a language of
the Perl family? They give opposite answers. PPT rewrote the *commands*
in Perl, and Perl stayed a guest in someone else's shell. rak rewrites
the *shell* into the language, and commands become optional.

| | Perl Power Tools (1999) | rak |
|---|---|---|
| **What is reimplemented** | The commands (`cat`, `ls`, `grep`…), one script each | The shell: words, pipes, redirections, aliases, as syntax of the language |
| **Unit of reuse** | A process: run `cat` from `$PATH` | A routine, method or block called in-process; external commands remain possible stages |
| **Who owns the pipe** | The host shell (`sh`, `cmd.exe`) | rak: `\|` is the [pipe](../../GLOSSARY.md#pipe) in [shell syntax](../../GLOSSARY.md#shell-syntax) |
| **Data between stages** | Bytes and lines, parsed again by every program | Typed values (lazy `Seq` or `Supply`); bytes only where a stage is an external command |
| **Redirection** | The host shell's, moving bytes | In the language, and format-aware: `@a >a.json`, `my %h <h.json` |
| **Goal** | Portability: wherever Perl runs, Unix's tools run | Expressivity: a shell's brevity and a language's power in one statement |
| **Model** | Clones of the POSIX tools, flags included | jq: stages are filters over values, and the language takes over what commands did |
| **Process cost** | Each command pays a full Perl startup, slower than the C tool | One process; the `~` and `#` sigils target the "too slow for small tools" complaint |

## Where they meet

Both move work from external binaries into the language. PPT did it by
duplication: each tool kept its interface and its process boundary. The
scripts have no callable API, so reusing one from Perl meant copying its
code or running it with `system`. Some PPT commands were not even pure
Perl: `awk` is a front end to Larry Wall's `a2p` translator. rak does it
by absorption: `<data.json | .users | map .name` replaces
`cat data.json | jq '.users[].name'` with no process at all. rak needs no
`cat.pl`, because a [load](../../GLOSSARY.md#load) (`<file`) is syntax.

## What rak lacks that PPT had

rak has no library of command equivalents. The plan does not say yet
whether `sort`, `uniq` or `wc` become rak routines, stay as `$PATH`
commands, or both. The open question on name resolution (Raku `sort` or
`/usr/bin/sort`?) is where PPT's idea could return, in a form PPT never
had: in-process routines that behave like the commands and pass values,
not bytes.

## What PPT teaches

Cloning every POSIX flag of a hundred tools is endless work with little
reward, and it is part of why PPT stalled. rak's jq-like route avoids
it: a few composable operations on values, and real commands for
everything else.

