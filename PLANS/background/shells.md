# A short history of shells

What a shell is, and how it evolved from RUNCOM to Nushell. The terminals shells run in
have [their own history](terminals.md).

## What a shell actually is

A shell is the layer that turns a sequence of typed or scripted commands into
system calls: it parses text, resolves names to executables, wires up file
descriptors, forks and execs processes, and gives you a language (variables,
control flow, functions) to glue programs together. Two design questions run
through its entire history:

1. **What travels between commands?** Unix shells settled on *unstructured
   byte streams* — everything is text, and programs are expected to parse
   each other's output. This is the "pipes and text" model.
2. **How much of a programming language should the shell be?** Early shells
   were thin command dispatchers with light scripting bolted on; later ones
   became full languages in their own right.

Nushell, at the far end of this history, revisits the first question and
answers it differently: structured, typed data instead of text.

## 1963–65 — Louis Pouzin's RUNCOM (CTSS)

The shell's ancestor isn't Unix at all. On MIT's **CTSS** (Compatible
Time-Sharing System), Louis Pouzin wrote **RUNCOM**, a facility that let a
user list a sequence of commands in a file and have them executed as if
typed at the terminal, with argument substitution (`$1`, `$2`, ...). This is
the first appearance of the ideas that define a shell:

- a **script** as an ordinary file, not a compiled program;
- **positional parameters** substituted into a template of commands;
- the notion of a *startup* command file — the name "RUNCOM" is where the
  `.rc` suffix (`.bashrc`, `.vimrc`, `.zshrc`, ...) ultimately comes from.

Pouzin also gets credit for coining the word **"shell"** itself, for the
protective layer of command interpretation wrapped around the raw
operating system.

## 1965–70 — Multics: the shell gets its name and its job

CTSS's successor, **Multics** (MIT, Bell Labs, GE), formalized the concept.
**Glenda Schroeder**, building directly on Pouzin's RUNCOM, wrote the
Multics shell as a distinct, replaceable user program rather than part of
the OS kernel — a separation of "command interpreter" from "operating
system" that Unix would inherit wholesale. Multics also introduced piping
commands together as a design goal, later realized fully in Unix.

## 1971 — the Thompson shell (Unix v1–v6)

When **Ken Thompson** and **Dennis Ritchie** built Unix at Bell Labs after
the Multics project wound down, Thompson wrote a small shell (`/bin/sh`)
carrying Multics's core idea — the shell as an ordinary, swappable user
process. It supported:

- I/O redirection (`<`, `>`),
- pipes (`|`), introduced in 1973 following a suggestion by **Doug
  McIlroy**, cementing "everything is text, programs compose via pipes" as
  the Unix philosophy,
- very limited scripting — no real control flow.

## 1977 — the Bourne shell (`sh`)

**Stephen Bourne**, also at Bell Labs, rewrote the shell for **Unix
Version 7**. The Bourne shell added what people now think of as basic
shell *programming*: `if`/`while`/`case`/`for`, shell functions, here-docs,
and a proper (if terse) quoting and expansion model. It became `/bin/sh` on
most Unix systems and the ancestor of the entire "Bourne family" — its
syntax is what POSIX later standardized.

## 1978 — the C shell (`csh`)

**Bill Joy**, then a Berkeley grad student, wrote **csh** for BSD Unix with
a different goal: make interactive use pleasant. It introduced, for the
first time in a mainstream shell:

- **command history** (`history`, `!!`, `!$`),
- **job control** (`^Z`, `bg`, `fg`, `jobs`),
- **aliases**,
- a syntax deliberately styled after the C language.

Its scripting language, however, was famously inconsistent and buggy
("csh programming considered harmful" — Tom Christiansen's later essay
catalogs the pitfalls). csh won the interactive-use battle but lost the
scripting one.

## 1983 — the Korn shell (`ksh`)

**David Korn** at AT&T Bell Labs set out to unify the two lineages: Bourne
syntax and scripting semantics, plus csh's interactive conveniences
(history, job control, aliases), plus new features of its own — command-line
editing (emacs/vi bindings), arrays, integer arithmetic, coprocesses. `ksh`
became the basis for the **POSIX shell** specification (1992), which
retroactively standardized "the Bourne family" as the portable baseline
every Unix shell still targets for `#!/bin/sh` scripts.

## 1987 — Aside: Perl, and what it did with shell's naked words and sigils

Perl isn't a shell — **Larry Wall** built it to replace the combination of
shell, `awk`, `sed`, and `grep` for text-wrangling and report generation.
But it inherited, and then argued with, two ideas straight out of shell
syntax, which makes it a useful mirror to hold up to the shells above.

**Sigils.** Shell has exactly one sigil: `$`, meaning "interpolate the
value of this variable" (`$foo`, `${foo}`). Everything else is a bareword.
Perl generalized that single sigil into a small type system, where the
sigil marks the *shape of the access*, not the variable's declared type:

- `$scalar` — one value,
- `@array` — a list, `$array[0]` still uses `$` because indexing an array
  yields one scalar,
- `%hash` — a key/value table, `$hash{key}` again uses `$` for the same
  reason,
- `&subroutine` and `*typeglob` for the rarer cases.

So `@` and `%` don't mean "array variable" and "hash variable" so much as
"I'm asking for the whole aggregate right now" — a distinction shell never
needed because shell has no native arrays or hashes to speak of (until
`ksh`/`bash` bolted them on later, without a sigil to match).

**Naked strings (barewords).** Shell's entire word model is "naked by
default": `ls foo bar` passes two literal strings; you only add punctuation
(`$`, quotes, `` ` ``) to opt *out* of literalness. Perl 4 and early Perl 5
carried that same permissiveness into a language with a real type system,
which is where it caused trouble:

- hash keys autoquoted — `$h{foo}` was silently `$h{"foo"}`,
- filehandles were barewords — `open(LOG, ">file")`,
- a bareword used as a string worked fine — until a subroutine of the same
  name was defined anywhere in the program, at which point the bareword
  silently became a *call* to that subroutine instead of a string, with no
  warning.

That last case — a shell-like "just a word" ambiguity colliding with a
real language's namespace of callable names — was a genuine bug magnet.
Perl's answer was `use strict 'subs'` (bundled into `use strict`, Perl 5,
1994): forbid bareword strings outright, and make quotes mandatory. It's
the same retreat Bourne's control structures represented over Thompson's
bare word-list, only aimed the other way: shell went from "no structure"
to "some structure over words"; Perl went from "shell-like naked words in
a typed language" back to "quote your strings, always."

## 1989 — Bash (Bourne-Again SHell)

**Brian Fox**, for the **GNU Project**, wrote **Bash** as a free
reimplementation of the Bourne shell that also absorbed features from ksh
and csh (history, job control, `$(...)` command substitution, arrays,
brace expansion, programmable completion added later by Chet Ramey, the
long-time maintainer). Bash's ubiquity — default shell on GNU/Linux and,
for a long time, macOS — makes it the shell most people mean when they say
"the shell" today.

## 1990 — Z shell (`zsh`)

**Paul Falstad** wrote zsh as a kitchen-sink shell: ksh-compatible, but
layering on nearly every interactive feature that had appeared anywhere —
advanced globbing, spelling correction, extremely rich completion, themeable
prompts. Frameworks like **Oh My Zsh** later turned that flexibility into a
plugin ecosystem, and Apple made zsh the default macOS shell in 2019.

## 2005 — fish (friendly interactive shell)

**Axel Liljencrantz**'s **fish** broke from POSIX compatibility on purpose,
treating "scripts other shells can run" as a non-goal in exchange for a
cleaner language and interactive UX that didn't need a config file full of
plugins to get: syntax highlighting, autosuggestions from history, and
readable scripting syntax out of the box, all by default rather than
bolted on.

## 2006 — PowerShell: the first real break with "everything is text"

**Jeffrey Snover**'s **PowerShell** (Microsoft), built on .NET, rejected the
Unix pipe model at its foundation. Instead of piping text that the next
command has to re-parse, PowerShell pipes **.NET objects** with typed
properties: `Get-Process | Where-Object CPU -gt 100` filters on an actual
numeric property, not a regex over columned text. This is the first
mainstream shell to treat "what flows through the pipe" as the thing worth
redesigning, rather than adding more scripting features on top of the
1973 pipe model.

## 2019 — Nushell: structured data, Unix-flavored

**Nushell** (`nu`), started by **Jonathan Turner** and **Yehuda Katz**
(both with prior work on Rust tooling), asks the PowerShell question again
but keeps Unix's terseness and composability instead of .NET's ceremony:

- every command's output is **structured data** — tables and records —
  not text, so `ls | where size > 10mb | sort-by modified` works on real
  typed fields;
- output is still rendered as readable text for a human at the terminal,
  but the *pipe* carries structured values;
- it's cross-platform and self-contained (written in Rust, ships its own
  consistent builtins) rather than shelling out to platform-specific
  `ls`/`grep`/`awk` and hoping their text formats agree;
- scripting syntax is deliberately more like a modern language (real data
  types, no accidental word-splitting) than csh/bash's accumulated
  quoting rules.

Where PowerShell solved "structured pipelines" by importing an entire
object system, Nushell solves the same problem while staying closer to
Unix's spirit of small, composable, plain commands — closing a fifty-year
loop back to McIlroy's pipe, redesigned for data instead of bytes.

## Shell timeline at a glance

| Year | Shell | Key contribution |
|------|-------|-------------------|
| 1963–65 | RUNCOM (Pouzin, CTSS) | Scripts, positional params, the word "shell" |
| ~1965 | Multics shell (Schroeder) | Shell as separate, replaceable user program |
| 1971 | Thompson shell | Redirection; pipes added 1973 (McIlroy) |
| 1977 | Bourne shell | Real control flow, functions — POSIX ancestor |
| 1978 | C shell (csh) | History, job control, aliases |
| 1983 | Korn shell (ksh) | Unified Bourne + csh strengths; POSIX basis |
| 1987 | Perl (Wall) | Not a shell; generalized `$` into sigils, then restricted shell-style barewords via `strict` |
| 1989 | Bash | Free Bourne-family shell, GNU default |
| 1990 | Zsh | Maximalist interactive features |
| 2005 | fish | UX-first, breaks POSIX compatibility |
| 2006 | PowerShell | Object/structured pipelines, .NET-based |
| 2019 | Nushell | Structured pipelines, Unix-style minimalism, Rust |


## The throughline

Every generational jump answers one of two recurring questions differently:
*how much language should the shell provide* (Thompson → Bourne → ksh →
bash/zsh kept adding), and *how much interactivity should it provide*
(csh → ksh → fish/zsh kept adding). Nushell and PowerShell instead reopened
the question nobody had touched since 1973 — what actually flows through
the pipe — and answered it with structure instead of bytes.

