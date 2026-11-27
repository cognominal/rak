# Aliases

Status: WIP — tested by `t/15-commands/rak/008-aliases.rak`, `009-aliases-gating.raku`,
and, from the startup file, `t/02-rakudo/rak/029-irak-startup-file.t`.

An [alias](../../GLOSSARY.md#alias) names a [command](../../GLOSSARY.md#command) and its
leading arguments. Aliases are what the [startup file](startup-file.md) was made for. The
decision and its alternatives are in
[ADR 0007](../../docs/adr/0007-an-alias-is-a-lexical-command-prefix.md).

## Spec

```rak
alias ll=ls -l              # ll src runs ls -l src
alias ll='ls -l'            # the same: a text that is one quoted string is unquoted
alias g='git log "--format=%an %s"'   # quotes group words, as in a command's arguments
alias ls=ls --color         # the inner ls is not an alias again
alias e=^echo               # ^ forces the external command, as at the prompt
alias hi=say hello          # an alias for a rak routine calls it: say 'hello', 'you'
hi you
alias                       # lists the aliases in scope, as alias name='text'
alias ll g                  # shows those; alias: x: not found for another name
type ll                     # ll is aliased to `ls -l', then ll's other meanings
```

- **What it is.** A command and its leading arguments: anything more is a `sub`. The
  words after `=` split and quote like a command's arguments, but nothing interpolates:
  `$x` and `{…}` stay text.
- **A declaration.** `alias` is a lexical declaration, known at compile time like a
  `sub`: seen from the statement after it to the end of its block. In irak, an alias from
  a submission or from the startup file lasts the rest of the session. An alias cannot be
  declared twice in one scope; an inner block can hide it.
- **Where it applies.** A word in command position: the start of a statement, of a
  `(…)` group, or of a pipe stage. `name(…)`, `&name` and `^name` never see aliases.
- **Lookup order** of such a word: keyword, alias, rak routine, builtin (`cd`, `type`, `ls`,
  the [topical commands](tables.md#topical-commands)), `$PATH`. Keywords cannot be aliased, nor be an alias's first word: `alias a=alias`
  and `alias a=if x` are compile errors. An alias hides a routine of the same name.
- **Expansion.** The alias's first word is looked up where the alias is used, by the
  same order, without that alias: `alias ls=ls -1` runs the routine or `$PATH` program
  `ls`. Aliases chain (`alias a=b x`, `alias b=echo y`: `a z` runs `echo y x z`); each
  expands at most once, so a cycle stops.
- **A rak routine target** is called with the words as strings. Such an alias cannot be
  redirected or be a later pipe stage.
- **Errors.** `alias ll=` with nothing after `=`, and an unclosed quote, are compile
  errors. A missing target throws "name: command not found" when the alias runs, as
  `^name` does.
- No `unalias`: an alias ends with its scope.
- `alias` is rak's: a routine named `alias` is not reachable by a statement starting with
  `alias`.

## Known gaps

- `alias` alone lists every alias of the enclosing scopes, including those declared
  later in the same block.

## Implementation notes

- An alias is the lexical constant `RAK-ALIAS name`, whose value is its text, then its
  words, joined by NULs. The grammar finds it through the resolver
  (`rak-alias-words` in `src/Rak/Grammar.nqp`), so it follows lexical scope and reaches
  irak's earlier submissions through their saved context.
- `rak-alias` in the grammar and actions declares or shows aliases; `rak-is-command`
  holds the lookup order; `rak-command-ast` expands an alias into the command's name and
  leading words.
- `RAK-ALIASES` and `RAK-ALIAS-DECLARED` in `src/core.c/Rakudo/Internals/RakFormat.rakumod`
  list aliases at run time and make a declaration show nothing; `RAK-TYPE` reports
  aliases first.
