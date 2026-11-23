# Perl

## Perl and Raku

Perl is a scripting language that was popular from the mid-1990s to the mid-2000s.
It began as one-liners used in shell pipes but quickly grew into a full scripting language — 
despite lacking a proper signature mechanism for functions.

Note that **Raku** denotes the language and **Rakudo** its implementation; **Rak** refers to both.

Like Rakudo, Rak is built on MoarVM, so libraries written in Raku can be used from Rak and vice versa. We also anticipate **Shak**, a simplified version that would run on a JavaScript engine.

Before discussing Rak further, we first define what a shell is, then trace its history from Pouzin's RUNCOM to Nushell. Since shells run inside terminals, we also cover the history of the terminal. This gives us a clear picture of what Rak should be in today's technological context.

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

In 1999 Tom Christiansen launched the **Perl Power Tools** (PPT), a
project that rewrote the standard Unix commands — `cat`, `ls`, `grep`,
`find`, `sort`, `diff`, `od`, `tar` and many more — in pure Perl, one
standalone script per command. The goal was portability: wherever Perl
ran, Unix's tools ran too, including systems that came without them.
Many contributors joined (Abigail wrote `cat`), and some commands got
competing versions. The project stalled in the 2000s; brian d foy
revived it, and it ships on CPAN as `PerlPowerTools` (`ppt` was its old
name), with about 120 programs today. It was a logical end point
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

