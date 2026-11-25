# Naked strings

A [naked string](../../GLOSSARY.md#naked-string) is an unquoted word that denotes a string
literal. The glossary gives the exact rule and the
[cheat sheet](../../rak-docs/CHEATSHEET.md#words-routine-calls-and-naked-strings) shows it in use.
Naked strings work in both the standard and the shell strategy.

Status: WIP, NEEDSPEC — implemented for words; escapes, interpolation and globbing are
planned, and the interpolation rule is open.

## Naked strings without Perl's trap

A shell treats words as strings by default. A language treats them as names. Perl tried
shell-style unquoted strings and gave up (`use strict 'subs'`), because such a word
silently became a call once a sub with the same name was defined anywhere in the
program. rak brings naked strings back with a rule based on order in the file: a word is
a call if its routine is already known *at that point in the file*, or if `(` follows
it. Otherwise it is a naked string. Words placed side by side are separate arguments, as
in a shell. So `say hello world` reads like shell and `say double 3` reads like a
language.

The parser decides with `is-identifier-known`, without `:exact`, so that setting routines
such as `say` count as known.

## Escaping out of ambiguities (planned)

Raku has many kinds of quoted strings; naked strings go the other way, and need a way out
when a word would otherwise mean something else. The planned rule is a backslash, which
also escapes spaces inside a naked string (`one\ string`). Syntax highlighting should make
the result visible.

- **Redirection characters.** A naked string cannot start with `<` or `>`, since those
  start a [redirection](redirection.md). Write `\<` or `\>`.
- **Paths that look like matches.** For naked strings to work as absolute paths, a match
  must start with `m` (`m/…/`), not a bare `/`. A relative path that starts with `m`
  therefore needs a backslash: `m\/` is the path `m/`, and `m\:s` the path `m:s`.

## Planned

- **Interpolation.** A naked string should interpolate variables, possibly subscripted:
  `https://api.github.com/users/$user`. Which characters end such a variable is an open
  question (see [URL targets](url-targets.md)).
- **Globbing.** `ls *.rak` should expand in both strategies.
- **Compile-time warnings.** A `sub` or `alias` added earlier in the file can still turn
  a naked string into a call, so the compiler should warn when a word that was a string
  in one place becomes a call in a later one.
