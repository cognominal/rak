# Spacing as syntax

rak removes characters that carry no meaning, especially brackets, and lets spacing carry
it instead. Sigils are not noise: they are kept and extended (see [sigils](sigils.md)).
Brackets around blocks are handled by [indentation](indentation.md); this document covers
spacing inside a line. The [cheat sheet](../../rak-docs/CHEATSHEET.md#spacing-is-syntax) shows the
rule in use.

Status: WIP — implemented for `>`, `>>` and `<`.

## Binary operators are written with spaces

A binary operator has whitespace on both sides. An operator that touches the next word is
something else, so `$a > $b` is a comparison while `say x >out` is an
[output redirection](../../GLOSSARY.md#output-redirection), and `@a >>+<< @b` stays a
hyperoperator while `>>log` appends. The touching rule settles the ambiguity without any
lookahead.

Unary operators are the opposite: they must touch their operand (`-x`, `!done`), and a
spaced unary token is read as binary.

## Why spacing makes room for shell syntax

Perl could not have had redirection syntax, because `>` and `<` were already comparison
operators. In [rak mode](../../GLOSSARY.md#rak-mode), spacing decides. The
[shell strategy](../../GLOSSARY.md#shell-strategy) takes the slot that Raku reports as the
error "two terms in a row", so adding it breaks no valid Raku program.

## Spacing and precedence

A statement on one line keeps Raku's precedence. A multi-line
[tree expression](tree-exprs.md) works differently: operators on one line have equal
precedence and associate to the left, and the column of each line's leading operator
gives its depth in the tree, so no parentheses are needed.

An earlier draft let spacing set precedence instead (an operator with less space around
it binding tighter). The two ideas conflict; choose one before tree expressions are
implemented.
