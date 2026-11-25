# An alias is a lexical command prefix, looked up before routines

A rak [alias](../../GLOSSARY.md#alias) stands for one command and its leading arguments,
not for text that is parsed again. It is a lexical declaration known at compile time, as
a `sub` is, because rak decides that a statement is a command while compiling it. A word
in command position is looked up as a keyword, then an alias, a rak routine, a builtin,
and last `$PATH`: bash's order, so an alias hides a routine of the same name, while
`name(…)`, `&name` and `^name` never see aliases.

## Considered Options

- **Text substitution, as in bash** (`alias g='git log | ^head'`). Rejected: rak's
  grammar parses the source it was given and cannot splice text into it; a pipeline or
  redirection is better written as a rak routine.
- **A runtime builtin, as in bash.** Rejected: an alias declared in a `.rak` file would
  not apply to the lines after it, which are compiled before it runs.
- **Routines before aliases.** Rejected: users bring bash habits, where an alias is
  looked up first, and `alias ls=ls --color` would otherwise do nothing when rak has an
  `ls` routine.

## Consequences

- An alias cannot be redeclared in the same scope; an inner block can hide it, and in
  irak each submission is a new scope.
- `alias` lists aliases at run time, from the lexical scopes of its caller.
