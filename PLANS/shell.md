# Git forking rakudo to make rak

This document has been written with the help of deepseek.
Most shortcomings are probably mine. I am only human.

I tried to be faithful to Larry Wall's spirit, being syntactically innovative  but in a 
context very different than the end of the 80s even if at least
in a specific point I reach an opposite conclusion : indentation
as syntax is good. This is not a academic work, I may have reinvented 
wheel without knowing and so maybe not giving proper credit.

Rak is both a full programming and a shell, interactive
or not, with some features inspired from nushell. Rak is forked from rakudo.
Beside being a shell it fixes limitations of rakudo, side steps costly features and uses a less noisy syntax. 
We use present tense but this is work in progress.
Rak is developped in rak git branch of `https://github.com/cognominal/rakudo`
or branches derived from it
and intended to be eventually merged to it.progress

Running a file with .raku extension is done with traditional semantic.

Rak being a shell in a terminal, this doc defines the two terms and gives a short history.
It also talks about charmbracelet, state of the art libraries to use terminal features.

## Implementation stages

We keep the hard parts last.

- new sigils

## Raku's costly features

Raku enables by default several features that are rarely useful yet impose a
significant performance cost — for instance, integers of arbitrary precision and
references to integers, floats, or strings.
Subscripting (walking data structures) is syntactically heavy.
To support synthetic types, UTF-8 was not adopted internally.
To support implicit references, variables that are not statically typed are boxed.


## Perl and Raku

Perl is a scripting language that was popular from the mid-1990s to the mid-2000s.
It began as one-liners used in shell pipes but quickly grew into a full scripting language — 
despite lacking a proper signature mechanism for functions.

Note that **Raku** denotes the language and **Rakudo** its implementation; **Rak** refers to both.

Like Rakudo, Rak is built on MoarVM, so libraries written in Raku can be used from Rak and vice versa. We also anticipate **Shak**, a simplified version that would run on a JavaScript engine.

Before discussing Rak further, we first define what a shell is, then trace its history from Pouzin's RUNCOM to Nushell. Since shells run inside terminals, we also cover the history of the terminal. This gives us a clear picture of what Rak should be in today's technological context.

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

## A parallel history: terminals, from Teletypes to Herdr

Everything above is about the **shell** — the command interpreter. But a
shell has to run *inside* something that draws characters and reads
keystrokes: the **terminal**. That's a separate lineage, and it's worth
tracing on its own, because Herdr — which you use daily — is its current
endpoint.

**Teletypes (1930s–1970s).** The literal, physical ancestor: a
teleprinter — the Teletype **ASR-33** is the canonical Unix-era example —
with a keyboard and a printer, no screen. "Terminal" meant an actual piece
of hardware bolted to a serial line. Unix conventions still carry its
fingerprints: `stty`, `tty`, and the very word "terminal" itself.

**Glass ttys and VT100 (1970s).** DEC's **VT52** (1975) and especially the
**VT100** (1978) replaced the paper with a screen but kept emulating a
serial terminal's behavior — including a specific set of cursor-control
**escape sequences**. The VT100's sequences became the de facto standard:
every terminal emulator discussed below, including Herdr, still describes
its baseline compatibility as "VT100-ish" or "xterm-ish," fifty years on.

**xterm (1984).** Written at MIT's Project Athena (Mark Vandevoorde, later
Thomas Dickey as long-time maintainer), xterm moved terminal emulation
into software, as a window on a Unix workstation running X11. It's the
reason a "terminal emulator" is a program at all rather than a serial
cable — and its escape-sequence dialect (`xterm-256color`, mouse
reporting, etc.) is the other baseline every later emulator targets.

**GNU Screen (1987).** The first mainstream **terminal multiplexer**:
run several windows inside one terminal session, and — critically —
**detach** from it and reattach later, from a different terminal
entirely. This is what made a remote Unix session survive a dropped SSH
connection, decades before "your agent kept working while your laptop
slept" was a design goal.

**tmux (2007).** **Nicholas Marriott** rewrote screen's idea with a
cleaner client-server architecture and saner configuration/scripting,
and tmux displaced screen as the standard multiplexer for the next
fifteen-plus years — panes, windows, sessions, a prefix key, all backed
by a persistent server process a client attaches to.

**GPU-rendered emulators (2016–2024).** A wave of emulators rewrote the
*rendering* side for speed and modern features, largely leaving the
multiplexing job to tmux: **Alacritty** (2016, Rust, minimalist and
GPU-accelerated), **kitty** (2017, Kovid Goyal, GPU-accelerated with its
own tabs/splits and an inline image protocol), **WezTerm** (2020, Wez
Furlong, Rust, with multiplexing built in, including over SSH), and
**Ghostty** (2024, Mitchell Hashimoto, Zig, native platform integration).
This is also the generation Omarchy's default terminals (Alacritty,
foot, kitty, Ghostty) come from.

**Herdr (2026).** Where tmux multiplexes panes for *you* to type into,
Herdr — from **herdrdev** (`herdr.dev`), written in Rust — multiplexes
panes that **AI coding agents** (Claude Code, Codex, Cursor, opencode,
and others) run in, plus your own shells alongside them. It keeps
tmux's model — a persistent server, workspaces/tabs/panes, a prefix key
— but adds what plain multiplexing never needed before: every pane
carries **agent state** (working, blocked, idle) that Herdr surfaces
directly, sessions ride out a disconnect, closed lid, or full reboot the
way tmux/screen sessions always have, and both keyboard-prefix and mouse
interaction are first-class rather than mouse being an afterthought. It's
the same detach/reattach idea GNU Screen introduced in 1987, extended
from "processes you started" to "agents that are still working when you
look away."

**tuios (2026).** A terminal window manager with a daemon, written in
Go, that manages sessions (named workspaces), each holding one pane per
window, grouped into numbered workspaces. A persistent daemon owns the
workspaces over a Unix socket, so sessions survive disconnection and
reboot the way tmux and screen always have. tuios goes beyond plain
multiplexing with an agent-native design: panes carry grants (read,
write, fan, respond, admin) for fine-grained access control, a query
socket lets in-pane processes inspect and control other panes by UUID,
and a tmux shim lets tmux-only tools drive tuios panes transparently.
Agents in tuios panes can announce their own state (working, blocked,
idle) that tuios surfaces in its UI alongside the person's view,
making it as much a multi-agent control surface as a terminal
multiplexer.

**charmbracelet (2022–2026).** A GitHub organization
(`github.com/charmbracelet`) that produces a stack of Go libraries and
tools purpose-built for terminal UIs. The core libraries are:

* **ultraviolet** — terminal I/O: keyboard and mouse events, screen
  buffers, styles, hyperlinks, clipboard, and color profiles.
* **bubbletea** — a TUI protocol and rendering framework: screen
  writing, terminal-size detection, cursor management.
* **bubbles** — reusable UI widgets: cursor, file picker, paginator,
  spinner, table, text area, text input, key binding help.
* **lipgloss** — border drawing and text wrapping.
* **glamour** — syntax highlighting.
* **harmonica** — spring-animation helpers.

These libraries are the building blocks behind several prominent
terminal applications. **tuios** uses ultraviolet, bubbletea, lipgloss,
and the bubbles cursor. **superfile** (`spf`, a terminal file manager)
uses ultraviolet, bubbletea, and the charmap encoding library. **gum**
(a shell-script TUI component tool) uses ultraviolet and bubbles.
**vhs** (a terminal GIF/cast recorder, also from charmbracelet) rounds
out the ecosystem.

### Accessing charmbracelet from Perl and Raku

Since the charmbracelet libraries are written in Go, calling them
directly requires bridging the language boundary.  Both Raku and Perl
have foreign-function-interface (FFI) facilities, and both can also
reach the libraries indirectly through the command-line tools they
power.

| Approach | Works today? | Effort |
|----------|-------------|--------|
| **Raku `NativeCall`** — built-in FFI. Load a `.so` and
declare function signatures. No extra modules needed. | Needs
`lib*.so` compiled from Go first | Medium |
| **Perl `FFI::Platypus`** — de‑facto FFI for Perl 5.
Attach C functions dynamically. | Needs CPAN install + `lib*.so` |
Medium |
| **`gum` sub‑process** — `gum` (already installed,
`/usr/bin/gum`) wraps ultraviolet + bubbles behind a clean CLI.
Call it with `run()` / backticks from any language. | **Works right
now** | Low |
| **tuios socket API** — the daemon at
`/run/user/*/tuios/tuios.sock` accepts JSON commands and emits
JSON-line events. Any language with a socket library can connect. |
**Works right now** | Low |
| **Go shim co‑process** — write a small Go binary that imports
the charmbracelet libraries and communicates over stdin/stdout as
JSON or line protocol. | **Works right now** (compile once) |
Low–medium |

**Raku** (`NativeCall`) works out of the box — no CPAN/Zef install
needed.  **Perl** needs `cpan install FFI::Platypus` (or the older
`Inline::C` / XS routes).  Neither has pre‑compiled charmbracelet
`.so` files available on this system yet, so the two practical paths
today are:

1.  **`gum` sub‑process** — trivially call `gum input`, `gum choose`,
    `gum style`, etc. from either language.
2.  **Write a thin Go shim** — a twenty‑line Go program that links
    the charmbracelet libraries and speaks JSON on stdio.

Once a `.so` is produced (`go build -o libultraviolet.so` with
exported C‑compatible wrappers), both languages can load it and call
the full charmbracelet API directly.

## Terminal timeline at a glance

| Year | Terminal / multiplexer | Key contribution |
|------|-------------------------|-------------------|
| 1930s–70s | Teletype (e.g. ASR-33) | Physical terminal: keyboard + printer, no screen |
| 1975 | VT52 (DEC) | First widely-used screen-based ("glass tty") terminal |
| 1978 | VT100 (DEC) | Escape-sequence dialect that became the de facto baseline |
| 1984 | xterm | Terminal emulation moves into software, on X11. Resizable, client informed thru SINGWINCH signal |
| 1987 | GNU Screen | Detachable multiplexing — sessions survive disconnection |
| 2007 | tmux | Client-server multiplexer, modern standard |
| 2016 | Alacritty | Minimalist, GPU-accelerated rendering |
| 2017 | kitty | GPU-accelerated + built-in tabs/splits + image protocol |
| 2020 | WezTerm | GPU-accelerated, multiplexing built in, incl. over SSH |
| 2024 | Ghostty | Native platform integration, Zig |
| 2026 | Herdr | Multiplexer for AI coding agents: agent-state-aware panes |
| 2026 | tuios | Terminal window manager with daemon: agent grants, pane control, tmux shim |

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

## Perl — from duct tape to solipsism

Perl was born in 1987 when Larry Wall, a systems administrator, needed a
ad‑hoc glue language — better than sed and awk, wider than the C shell,
still happy talking to Unix processes. He took variable syntax from C,
string processing from awk and sed, the `$_` default from a dozen Unix
one‑liners, and welded them together so the language felt natural to
someone who spent the day piping commands. It spread through USENET as
the answer to "I need to parse this log, munge those columns, and email
the result before lunch."

By the mid‑1990s Perl was the **duct tape of the internet**. The CGI
boom made it the default for dynamic web pages — a `.pl` file dropped
into `cgi-bin` was a web application. CPAN, launched in 1995, gave Perl
a library network that no other language matched for years. TIMTOWTDI
("There's More Than One Way To Do It") was celebrated as freedom from
dogma.

In 1998–99 Tom Christiansen launched the **Perl Power Tools** (also
called ppt or PIT), a project that rewrote every standard Unix command
— `cat`, `ls`, `grep`, `find`, `sort`, `diff`, `make`, `yacc`, and
hundreds more — entirely in pure Perl. The goal was portability: if you
had the Perl interpreter, you had a Unix environment, whether you were
on VMS, Windows, or an embedded board. The project reached over 200
commands and was bundled as `ppt` on CPAN. It was a logical end point
for Perl's original mission — the language that began as "better awk +
sed" now swallowed the entire Unix toolchain — but it also foreshadowed
a turn inward: rather than improving the system's tools, Perl would
recreate them inside its own world.

Yet even at its peak Perl remained strictly a **language inside a shell
pipe**, never a shell itself. The canonical way to use Perl from the
command line was through dozens of cryptic switches: `perl -e`
("execute this one‑liner"), `perl -n` ("wrap code in `while (<>){ }`"),
`perl -p` ("print after each line"), `-a` ("autosplit into `@F`"),
`-F` ("split pattern"), `-l` ("chomp and add newline"), and many more.
A programmer invoking Perl on the command line had to learn both the
language and an ever‑growing manual page of switches, because Perl had
no pipe or redirection syntax of its own — it was a guest in someone
else's shell.

Two concrete examples. Filtering a pipeline by pattern required piping
into a `-ne` one‑liner, with the shell owning the pipe and Perl only
seeing stdin:

```
dmesg | perl -ne 'print if /error|fail/i'
```

To mimic `sed -i` you wrote a different constellation of flags:

```
perl -i -pe 's/foo/bar/g' file.txt
```

Every flag (`-i` for in‑place edit, `-p` for print loop, `-e` for
inline code) was a separate Unix‑style switch, each with its own place
in the argument order, its own gotchas, its own reason to misremember.
The language had no syntax for `input > filter | transformation >
output` — you had to leave the language, encode the dataflow in shell
syntax, and let the operating system wire the pipes. Perl lost the
opportunity to move from being a language *used in* a shell to being a
shell language itself, with native pipe and redirection operators,
because it never tried to become the outer layer — it stayed content
being the clever guest.

Then the web moved on. PHP ate the CGI niche. Ruby and Python offered
cleaner object systems. Perl 6, announced in 2000 as a complete rewrite,
became a 14‑year research project into grammars, multi‑dispatch,
junctions, and dozens of ideas that were linguistically fascinating and
relationless to the problems that had made Perl popular. The community
split: Perl 5 maintained compatibility without innovation, while
Perl 6 — renamed Raku in 2019 — produced a language admired for its
design and used by almost nobody. TIMTOWTDI curdled into a culture where
every script invented its own idioms, every CPAN module its own object
system, and reading someone else's Perl required decoding a private
orthography of `$;` and `@+` and `*%` that looked like a closed society
writing for itself. Perl became the language a programmer loved alone at
a terminal — an autist solipsism in which the joy of constructing
elaborate regular expressions replaced the joy of shipping working
software.

Python, released in 1991, took the opposite path from its first line.
Guido van Rossum designed a language that was **readable by default**:
significant whitespace enforced consistent indentation, "one obvious
way" replaced TIMTOWTDI, and the syntax was deliberately un‑fancy so
that code communicated intent without ceremony. Where Perl celebrated
cleverness, Python celebrated clarity.

The decisive divergence came with libraries. Perl's CPAN was a
peer‑to‑peer network of independent modules with no central quality
control. Python's "Batteries Included" philosophy — a rich standard
library covering HTTP, XML, databases, compression, GUIs, and testing —
meant newcomers could import `urllib` or `sqlite3` without hunting for a
module whose author had stopped answering email in 2004. (Raku would
eventually adopt the same idea with **Rakudo Star**, first released April
2010 — a curated distribution bundling the Rakudo compiler, commonly
used modules — but by then the ecosystem had already scattered.)

Then came NumPy (2005). The `numpy` library exposed a multidimensional
array written in C and Fortran — the performance of compiled code with
the ergonomics of a scripting language. Python became the
**library‑access language**: you wrote three lines that loaded NumPy,
called SciPy for signal processing, matplotlib for plotting, and
scikit‑learn for classification; the real work happened in compiled
libraries that Python orchestrated. TensorFlow, PyTorch, and JAX
followed the same pattern — Python is the thin, readable shell around a
compiled core.

A smaller but telling difference: Python gives every function a
visible, introspectable **signature**. Function annotations landed in
Python 3.0 (2008, PEP 3107), `inspect.signature()` in 3.3 (2012,
PEP 362), formal type hints in 3.5 (2015, PEP 484), and
positional‑only parameter markers (`/`) in 3.8 (2019, PEP 570). Any
tool — IDE, linter, decorator — can query `inspect.signature(fn)` and
learn the parameter names, kinds, defaults, and annotations. Perl has
nothing comparable: Perl 5 prototypes (`sub foo($$)` 1994) only hint
at context, not names or types; the experimental `use feature
'signatures'` (5.20, 2014) gives named parameters but no runtime
introspection, no annotations, and no standard way to reflect on a
function from outside. Raku finally has real signatures, but that is
a different language.

The critical difference from Perl is that Python never tried to be its
own universe. It remained a thin layer that imported power from
elsewhere. Where Perl retreated inward (rewriting `cat` in Perl,
inventing Perl‑only object systems, designing Perl 6 for a decade),
Python advanced outward (the Jupyter notebook, the PyData stack, PyPI
becoming the largest package repository on Earth, ML frameworks pushing
the language into new domains). Perl asked "What can the language do?";
Python asked "What can the language access?"

## The throughline

Every generational jump answers one of two recurring questions differently:
*how much language should the shell provide* (Thompson → Bourne → ksh →
bash/zsh kept adding), and *how much interactivity should it provide*
(csh → ksh → fish/zsh kept adding). Nushell and PowerShell instead reopened
the question nobody had touched since 1973 — what actually flows through
the pipe — and answered it with structure instead of bytes.

## rak as the outer layer: the best of both worlds

Perl was always a guest in someone else's shell. People could write
`dmesg | perl -ne '…'`, but the shell owned the pipe and the redirection,
and Perl only saw stdin. rak takes the opposite position: the language
*is* the outer layer. It keeps the shell's composition (words, pipes,
redirections) and the language's power (types, signatures, data
structures), and it uses syntax to settle the conflicts between them.

### Naked strings without Perl's trap

A shell treats words as strings by default. A language treats them as
names. Perl tried shell-style unquoted strings and gave up
(`use strict 'subs'`), because such a word silently became a call once a
sub with the same name was defined anywhere in the program. rak brings
naked strings back with a rule based on order in the file: a word is a
call if its routine is already known *at that point in the file*, or if
`(` follows it. Otherwise it is a naked string. Words placed side by
side are separate arguments, as in a shell. So `say hello world` reads
like shell and `say double 3` reads like a language.

### Spacing makes room for shell syntax

Perl could not have had redirection syntax, because `>` and `<` were
already comparison operators. In rak mode, spacing decides: `$a > $b`
with spaces is a comparison, and `say x >out`, with `>` touching its
redirection target, is an output redirection. The shell strategy takes
the slot that Raku reports as the error "two terms in a row", so adding
it breaks no valid Raku program.

### Redirection on values, not only bytes

In Unix a redirection moves bytes, and every program parses them again.
In rak the redirection target's extension picks a format: in value mode,
`@a >a.json` encodes the value as JSON; the load `my %h <h.json` decodes
it; and `.jsonl` holds one record per line. Inside the language, data
stays typed. At the file system boundary it is encoded in a format.
McIlroy's "text is the universal interface" still holds at the edges,
and structure holds inside.

### Walking data, à la jq

Dotty subscripts (`%h.users.1.name`, `.b.1` on the topic) and `->meth`
for parameterless method calls give the short paths of jq inside a full
language. Text pipelines break down as soon as data is nested; paths do
not.

### Pipes: a stage can still be a command

A pipeline stage is either:

- an **external command** (`ls`, `git log`, `jq`), which reads and
  writes bytes as in any Unix shell, or
- a **rak routine, method or block**, which reads and writes values,
  with no fork and no process.

Both kinds can be mixed in one pipeline. Where a command and a rak stage
meet, data is converted: bytes become lines (or decoded values when a
format is given), and values become text (or are encoded in a format
such as JSON or JSONL).

The tendency, though, is to move into the language what used to be a
command. jq is the model. jq is a command, but inside jq, `|` chains
filters over JSON values, and a filter can emit zero, one or many
values (`.users[] | .name`). rak supports pipes à la jq as a language
feature: stages pass values, and a stage that emits several values
produces a lazy `Seq` (or a `Supply` when the stream is asynchronous),
so pipelines stream instead of collecting everything first. Raku's feed
operators (`==>`) already point in this direction.

In the shell strategy, `|` is the pipe. In the standard strategy it keeps
its Raku meanings, the `any` junction (`1 | 2`) and the slip (`|@a`).
Unlike `>` and `<`, spacing can't separate the two uses, so the
strategy decides.

```rak
# tentative syntax
git log --format=%an | sort | uniq -c    # all commands: a plain Unix pipe
git log --format=%an | ->unique | ->sort  # a command, then rak methods on lines
<data.json | .users | map .name          # jq-like: no process at all
```

So `curl … | jq '.users[].name'` doesn't need jq any more: the language
does what the command did. But nothing forbids keeping jq, or any other
command, as a stage. rak takes on what commands do. It does not exclude
the commands themselves.

A pipe is not a redirection: a redirection attaches one statement's
output or input to a redirection target, while a pipe connects stages.

### irak: the REPL as a pipe through time

In irak, the irak topic `$_` holds the value of the previous irak
submission, so each submission works on the output of the one before.
This is the interactive habit of growing a pipeline one stage at a time,
but the values passed between stages stay structured.

### Speed

The new sigils `~` and `#` hold native `str` and `int` values with no
boxing. This targets one reason people left Perl and Raku for small
tools: those languages were too slow to start and too slow at simple
work.

### Open questions

- **Name resolution.** When `sort` is both a Raku routine and
  `/usr/bin/sort`, which one wins? Aliases, routines, builtins and
  `$PATH` commands need one documented lookup order, made visible by
  `type`.
- **Naked strings can still change meaning.** "Known at this point" is
  easier to predict than Perl's rule, but a `sub` or `alias` added
  earlier in the file can still turn a naked string into a call.
  Compile-time warnings matter.
- **Choosing the strategy, and quoting.** scsh, psh, xonsh, Oil/YSH,
  PowerShell and Nushell all ran into these two problems. rak chooses
  between the standard and shell strategies per statement or
  parenthesized group, with explicit escapes (`\(`). This is the area to
  test most thoroughly.
- **Entering the shell strategy without a command.** Since `|` is a pipe
  only in the shell strategy, a pipeline whose first stage is not a
  command, such as `<data.json | .users | map .name`, needs a rule that
  puts it in the shell strategy. Otherwise it parses as a junction.

### Status

Done: naked strings, spacing as syntax, redirection with formats and
loads, dotty subscripts, the irak topic, and the new sigils. Planned:
running external commands, pipes, `alias`/`type`, globbing, indentation
in place of braces, and URL redirection targets.

## Larry Wall, natural language and pragmatics

Larry Wall studied linguistics before he wrote Perl. He and his wife
Gloria were graduate students in linguistics at UC Berkeley, preparing
to become missionary linguists: to live with a people whose language
had no written form, write it down, and help translate the Bible. The
plan was abandoned, and Wall went to work at NASA's Jet Propulsion
Laboratory instead
([Wikipedia](https://en.wikipedia.org/wiki/Larry_Wall)). He calls
himself "a 50/50 hybrid" of linguist and computer scientist
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).

In *Natural Language Principles in Perl*
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)),
he argues that a computer language should borrow from how people really
speak. Some of its principles, in his words:

- **Learn it once, use it many times**: "You learn a natural language
  once and use it many times."
- **Learn as you go**: "It's okay if a language is difficult to learn,
  as long as you don't have to learn it all at once."
- **Multiple ways to say the same thing**: "Just because Perl is the
  melting pot of computer languages doesn't mean you have to stir."
- **Local ambiguity is okay**: "People thrive on ambiguity, as long as
  it is quickly resolved."
- **Topicalization**: "A topicalizer simply introduces the subject
  you're intending to talk about."
- **Pronominalization**: "`$_` means "it", and `@_` tends to mean
  "them"."

Elsewhere he sums it up: "Natural languages are not orthogonal, they're
diagonal"
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).
And the preface of *Programming Perl* states the goal: "Perl is designed
to make the easy jobs easy, without making the hard jobs impossible"
([O'Reilly](https://www.oreilly.com/library/view/programming-perl-3rd/0596000278/pr02.html)).

### Pragmatics

Linguists split meaning into layers. **Syntax** is how words combine.
**Semantics** is what the combination means on its own. **Pragmatics**
is what it means *in context*: who is speaking, to whom, when and why.
"Can you pass the salt?" is a question about ability by its semantics,
and a request by its pragmatics. Pragmatics studies:

- **deixis**: words that point to the situation, such as *I*, *here*,
  *now* and *that*;
- **implicature**: what is meant without being said (Grice's
  cooperative principle: say as much as needed, no more, and stay
  relevant);
- **ellipsis**: leaving out what the context already provides.

Wall doesn't use the word, but context is at the center of his
thinking. The school of linguistics he trained in, tagmemics (developed
by Kenneth L. Pike), "makes a big deal about context", and of human
listeners he says: "If there's a way to make sense of something in a
particular context, they'll do so"
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).
`$_`, default arguments and context-sensitive operators are pragmatics
turned into language features: a program is said *in* a context, and a
good language lets that context do part of the work.

### Spoken first

Natural languages are spoken before they are written. Speech is far
older than writing, and most of the world's languages have never been
written down. Academies like the Académie française, founded by
Richelieu in 1635
([Wikipedia](https://en.wikipedia.org/wiki/Acad%C3%A9mie_fran%C3%A7aise)),
have tried to legislate the written language for centuries, but usage
wins: speakers shorten, borrow and reshape words, and dictionaries
follow, sometimes generations later. Writing is the formal register;
speech is where the language lives and changes. Wall notes what writing
loses: "Natural language is naturally punctuated by the pitches,
stresses and pauses we use to indicate how words are related"
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)).
rak's spacing rules are a form of that prosody: `$a > $b` and `say x >out`
differ only in where the pauses fall.

### The command line is a conversation

A program file is the written register: composed, revised, read by
others later. The command line is the spoken register:

- **turn-taking**: the prompt hands the floor to you, the output answers;
- **shared context**: the current directory, the history, the previous
  result;
- **deixis and ellipsis**: `cd -`, `!!` and `$_` point to what was just
  said instead of repeating it;
- **repair**: you recall a line, fix it and say it again;
- **short turns**: nobody declares variables in a conversation.

So the command line fits Wall's thesis even better than a program file
does. That is the missed opportunity. Perl applied natural-language
principles to the written register, while the spoken register, the
shell, stayed with `sh` and its descendants. Wall himself pointed at
the shells' grammar: unlike Perl, they "make use-vs-mention distinctions
using a `$` prefix"
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)).
rak's naked strings take that distinction back: a naked string mentions
a word, and a sigil uses a variable. Raku went further toward the formal
register. rak takes up the opportunity: the standard strategy is the
written register, the shell strategy is the spoken one, and irak is the
conversation, where the irak topic `$_` is the "it" of the previous irak
submission.

## Huffing: rak and the Huffman principle

In 1952 David A. Huffman found the optimal way to encode symbols: give
the most frequent symbols the shortest codes. Wall made it a design
rule for Perl 6: "Common operations should be "Huffman coded." That is,
frequently used operators should be shorter than infrequently used
ones"
([Apocalypse 3, 2001](https://web.do.metacpan.org/pod/share::Apocalypse::A03)).
He applies it to his own language: "For how often it's used, the
`scalar` operator of Perl 5 is too long, in my estimation."

We use the shorter verb **to huff**: to give a construct a spelling
whose length fits its frequency. Common constructs are huffed short;
rare ones may be *unhuffed*, made longer and more explicit, to free a
short spelling for something more common. (In everyday English, to huff
is to puff or to sulk. Here it is jargon. Shortening "Huffman code" to
"huff" is itself a huff.)

### Natural language huffs itself

Huffing isn't an invention of programmers. Zipf's law of abbreviation
([Wikipedia](https://en.wikipedia.org/wiki/Brevity_law)), from his 1935
book *The Psycho-Biology of Language*, says that frequent words tend to
be short, and speakers keep shortening the ones that become frequent:

- *omnibus* → *bus*, *laboratory* → *lab*, *television* → *TV*;
- *métropolitain* → *métro*, *réfrigérateur* → *frigo*,
  *cinématographe* → *cinéma* → *ciné*;
- pronouns huff whole noun phrases: "the file we just loaded" → "it".

None of these were decreed by an academy. Speakers huffed them, and the
written language followed. That is the sense in which rak huffs Raku:
it shortens what the conversation uses most.

### What rak huffs

| Raku | rak | What gets cheaper |
|---|---|---|
| `say 'foo'` | `say foo` | naked strings: no quotes |
| `f 'a', 'b'` | `f a b` | arguments placed side by side: no commas |
| `%h<name>`, `@a[1]` | `%h.name`, `@a.1` | dotty subscripts |
| `$_<name>` | `.name` | the topic, implicit |
| `$obj.meth` | `$obj->meth` | parameterless method call |
| `my str $s`, `my int $n` | `my ~s`, `my #n` | the new sigils |
| `spurt 'f.json', to-json @a` | `@a >f.json` | output redirection with a format |
| `my %h = from-json slurp 'f.json'` | `my %h <f.json` | load |

Planned huffs include one-letter variables without sigils, indentation
in place of braces, and pipes in the shell strategy.

### What huffing costs

Short spellings are a limited resource: each one is taken from
something else. In rak, `.5` is `$_[5]`, not a number; `#n` is a
variable, so comments need a space after `#`; `~foo` is a variable, not
"stringify `foo()`"; and `.meth` without parentheses is a subscript.
Each of these unhuffs a rare Raku construct to huff a frequent rak one.
That trade is worth it only when frequency justifies it, and frequency
on the command line is not the same as in a module. This is why the
huffs are limited to rak mode: `.raku` files keep Raku's spellings.

## forking rakudo to rak to make it a (also) a shell

Beside making it  a shell rak minimizes the visual noise and 
improves readability. Indentation and spacing is not mere tokens 
separator but syntax.

### examples




```rak
if 1
  say hello world
  say salut
  say one\ string\ hello\ world 
```


```rak
if 1 {
  say "hi", "world";
  say "salut";
}
```


  
## naked strings 

## operators 


### Binary operators 

Binary operator (short: binop) must be surrounded by spaces.

#### Multi line expressions (aka tree exprs)

Newline terminate statements. The exception is multi line expressions.
They partially mirror the corresponding generated tree. 
Within a line there is no operator precedence, an 
binop with less space around it binds more than one with more.

Unary operators must not be separated from their operands.

Subtrees binop are left associative. 


```rak
  1 + 2
* 3 + 4 
- 5 + 6
```
is equivalent to the next tree expr that overdo it

```rak
    1
  + 2
*   3
  + 4
-   5
  + 6
  
```

is equivalent to

```rak
((1 + 2) * ( 3 + 4)) - (5 + 6)
```



## other adaptations 

Some syntax adaptations are needed to support naked strings,
pipes and redirections 

Functions must be called with parentheses.  
A name without a parentheses is a command/function call. 
Indentation is used as syntax, so braces are not needed for
multi lines blocks.
Redirections are a sort of prefix operators followed by the path operand.
Binary 


## Boxing, Scalars, and why rak sigils skip them

### The cost of `$`

In standard Raku, every `$`-sigiled variable is backed by a `Scalar`
container object — a "box" that wraps the value. That box enables
useful things:

| Capability     | What it enables                                          |
|----------------|----------------------------------------------------------|
| Aliasing       | Two names can share the same storage (`:=`)              |
| `is rw` params | A callee can mutate the caller's variable                |
| Undefined state| Variable can be `Nil`/`Any`; you can test `.defined`     |
| Type flexibility| A `$` variable can hold any type at runtime             |

But the box has real costs:

- **Indirection on every access** — variable → `Scalar` → value, one more
  pointer hop even before touching the data.
- **Allocation on every write** — Raku `Int`/`Str` are immutable, so
  `$sum = $sum + 1` allocates a new object every time.
- **GC pressure** — those short-lived objects must be reclaimed.
- **JIT impedance** — the JIT has to unbox/rebox through the container,
  making it harder to keep values in machine registers.

A native variable (`my int $x`, `my str $s`) skips the box: the value
lives in a raw machine slot. But the `$` sigil hides that distinction —
you can't tell from the variable's *face* which kind it is, and you still
need the explicit type annotation.

### The rak sigils: native by default, no boxing

Rak adds two sigils whose **glyph alone guarantees the machine-level
type** — no `Scalar` container, no explicit type annotation:

```raku
my ~name = "Alice";   # native str — no box
my #age  = 30;         # native int — no box
```

They are wired through the same code path as `my str $x` / `my int $x`
in the Rakudo compiler (`IMPL-CONTAINER` returns `nqp::null` when
`$of` has a native primitive spec), so they inherit all the benefits
of native scalars:

- **No container indirection** — a `~`/`#` variable is a raw lexical slot.
- **No per-operation allocation** — `#n + 1` is a machine `add` producing
  another machine word; no GC churn.
- **~13× faster in tight loops** — benchmarked against boxed `Int`
  (30M increments: ~0.034s for `#sum` vs ~0.45s for `Int $sum`).
- **JIT-friendly** — the JIT keeps a native local in a register across
  iterations and emits a tight native op. The boxed version forces
  unboxing/reboxing speculation.
- **No overflow/representation branching** — machine `int` is fixed-width;
  boxed `Int` checks every operation whether the result still fits fixnum
  or must promote to bignum.

Because the sigil *is* the type, explicit type annotations are a
compile error:

```raku
my Str ~name = "Alice";   # COMPILE ERROR: ~ already implies Str
my int #age  = 30;        # COMPILE ERROR: # already implies int
my Int #age  = 30;        # error too, even the "boxed" Int
```

`where` constraints still work (`my ~name where *.chars > 0 = "Alice"`)
since they add a runtime check, not a type.

### Why native values, not boxes?

The entire reason `~` and `#` exist is to drive subscripting (§ below).
A subscript **reads** a key or index once to decide where to look;
it never needs to:

- write back through the subscript expression itself,
- keep a live alias to the variable that supplied the key, or
- hand the key off expecting mutation-by-reference.

So the `Scalar` container's whole purpose — aliasing, rebinding,
rw-by-reference — is dead weight for this use case. A plain native
value is not a compromise; it's the right-sized tool. If you genuinely
need aliasing, `is rw`, or undefined state, that's what `$` with an
explicit type is for.

### What you give up

- **No `Nil` / undefined state** — `~s` defaults to `""`, `#n` to `0`.
- **No aliasing (`:=`)** — `~a := ~b` is not supported.
- **No `state` variables** — inherited from Rakudo's native-scalar
  limitation (`state str $x` is NYI, so `state ~x` is too).
- **No `is rw` parameters** on `~`/`#` — they can't be passed by
  reference to mutate the caller's variable.

## The `~` sigil — native `str`

```raku
my ~name = "Alice";
~name = "Bob";             # reassign, same as any variable
say "Hello, ~name!";       # interpolates in qq strings
my ~name where *.chars > 0; # where clause still works
```

Mnemonic: `~` is already Raku's string-flavoured operator
(concatenation `$a ~ $b`, stringify prefix `~$x`). A `~`-sigiled
variable is "the string one."

Grammar detail: bare `~identifier` always means the sigil, never the
prefix stringify operator. Write `~ foo` (space) or `~(foo)` if you
need the old bareword-stringify reading. `~$x`, `$a ~ $b`, `~~`, `~=`
are all unaffected.

## The `#` sigil — native `int`

```raku
my #count = 0;
#count = #count + 1;       # machine add, no boxing
loop my #i = 0; #i < 10; #i++  { ... }
```

Mnemonic: `#` conventionally means "number/count" (item #3, #items).
A `#`-sigiled variable is "the number one."

**Comment change:** Because `#` can now start a term, a plain `#`
followed by a letter or underscore with **no space** is a variable
reference, not a comment. `# this is fine` (space); `#TODO: fix` now
looks like the variable `#TODO`. Add a space after `#` for comments.
`` #`(...) `` and `#|`/`#=` are unaffected.

## Proposed `^` sigil — native `num` (float)

Following the same pattern, a natural next sigil is `^` for native
float (IEEE 754 `num`):

```raku
my ^pi     = 3.14159;         # native num, no box
my ^radius = 5.0;
say 2 ^ ^pi * ^radius;        # infix ^ (exponentiation) is spaced both sides;
                               # bare ^pi touching → the sigil
```

**Why `^` is a good fit:**

- **`^` already means "float" in Raku** — `num` (native float) is
  displayed as `^` in `.raku` output. The association "caret = float"
  is already culturally wired.
- **No term-position collision** — prefix `^` (hyper meta-operator)
  requires a space or `(...)` to start a term; `^foo` touching an
  identifier is unclaimed grammar. Same disambiguation rule as `~`:
  touching → sigil, space → old meaning.
- **Twigil `$^` is an existing, separate feature** — `$^foo` (dynamic
  variable twigil) is a different grammatical position (after `$`,
  not at term start), so no collision.
- **Mnemonic:** `^` "points up" like a decimal point, and it's
  the exponentiation operator — float territory.

## Walking data structures with `.` (dotty subscript sugar)

`~` and `#` aren't just a nicer way to declare typed variables. Their
real payoff is **bracketless subscripting**, because their sigil alone
guarantees the value's type, so the parser can desugar unambiguously
*at parse time* — no runtime type check, no FALLBACK method.

### The problem `~`/`#` solve

Raku already lets a variable drive a subscript, but only with explicit
brackets: `.%h{$key}` / `.[$idx]`. A bare `$`-sigiled variable carries
no static type information — the parser can't know whether to emit
positional `[...]` or associative `{...}` access without a runtime check.

`~foo` is provably a string → associative subscript `{...}`.
`#bar` is provably an integer → positional subscript `[...]`.

### The dotty sugar (`.rak` mode)

After a term, `.` followed by one of these shapes desugars as follows:

| after `.`              | desugars to   | subscript kind          |
|------------------------|---------------|-------------------------|
| bare integer (`1`)      | `[1]`         | positional, literal idx |
| bare identifier (`key`) | `<key>`       | associative, literal kw |
| `~expr`                 | `{~expr}`      | associative, string key |
| `#expr`                 | `[#expr]`     | positional, int index   |
| `^expr` (future)        | `{^expr}` or `[^expr]`? — see below |

So:

```raku
@a.1.toto.~str.#int  ≡  @a[1]<toto>{~str}[#int]
```

### `->` for parameterless method calls

Because `.name` now means `<name>` (a literal associative key lookup),
parameterless method calls move to `->name`:

```raku
@a->elems          # was @a.elems — call method elems with no args
@a.elems           # now means @a<elems> — subscript by literal key "elems"
@a.elems()         # still a method call (parentheses make it explicit)
@a.elems: sort     # still a method call with adverb (colon disambiguates)
```

This only applies in `.rak` files; `.rakumod` / `.raku` / `.pm6` files
keep standard Raku semantics.

### Why `~`/`#` are the prerequisite

Without fixed-type sigils, you can't write `.~foo`/`.#foo` without
brackets — the parser needs to decide `{}` vs `[]` before runtime, and
only a sigil that *guarantees* the type (str vs int) provides that
information. `~` and `#` are the first two; `^` for float would be the
natural third.

### What about `^` in the dotty sugar?

A float sigil `^expr` could desugar to either subscript kind depending
on use case. Likely candidates:

| Interpretation | Meaning |
|----------------|---------|
| `[^idx]`       | positional, using a float as an index (truncated to int) |
| `{^key}`       | associative, using a float as a key (stringified or exact) |

The most consistent answer: since `#` (int) takes the positional branch
and `~` (str) takes the associative branch, a float could follow
`#`'s pattern (positional, since `num` is numeric like `int`), or a
separate rule could reserve it for a future float-keyed collection.
The rak branch explicitly leaves "sigils for other types" out of MVP;
`^` would be designed when there's a concrete use case for it in the
dotty sugar.

