# Unsettled

A bird's-eye view of the design questions still open in rak. Each entry is one line and
links to where the question is discussed. [ADRs](../docs/adr/) record decisions once they
are made; [status.md](status.md) tracks what is built. When a question here is settled,
record it in an ADR (or in the feature document, for a small one) and remove it from
this list.

## Language shape

- **Calling a routine as a command.** Whether a routine needs `(…)` in the shell
  strategy. The lookup order of names is settled in [aliases](features/aliases.md).
  [strategies](features/strategies.md#open-questions)
- **Precedence by spacing or by column.** An old draft let spacing set precedence within
  a line; tree expressions make a line's operators equal and use columns instead. Choose
  one. [spacing](features/spacing.md#spacing-and-precedence),
  [tree expressions](features/tree-exprs.md)
- **Indentation details.** Comments, blank lines, here-documents and error reporting in
  indented blocks. [indentation](features/indentation.md#open-questions)

## Sigils and variables

- **A `^` sigil for native `num`.** Whether to add it at all, and whether `.^x` would be
  a positional or an associative subscript. [sigils](features/sigils.md#proposed--sigil--native-num-float),
  [dotty subscripts](features/dotty-subscripts.md#what-about--in-the-dotty-sugar)
- **One-letter variables without a sigil.** The letter-to-type table, and how `say s`
  chooses between the variable and the naked string `"s"`.
  [sigils](features/sigils.md#one-letter-variables-without-a-sigil-planned)
- **Autovivification on read.** Whether irak may create missing paths that a `.rak` file
  may not. [dotty subscripts](features/dotty-subscripts.md#reading-a-missing-path-planned)

## Words and strings

- **Escapes and interpolation in naked strings.** The backslash rules, and where an
  interpolated `$var` ends inside a word (URL targets settled it for URLs).
  [naked strings](features/naked-strings.md), [URL targets](features/url-targets.md#decisions)

## Redirection and data

- **Standard error and stacking.** File-descriptor prefixes (`2>file`, `2>&1`) or colon
  pairs (`:err>file`). [redirection](features/redirection.md#stacking)
- **HTTP beyond GET and POST.** How to spell PATCH, PUT and DELETE, overriding a URL
  target's format, and pagination. [URL targets](features/url-targets.md#open-questions)
- **myaml matching.** What a match returns over lists, and whether `::=` and `:::=` are
  two operators. [myaml](features/myaml.md#open-questions)
- **Key order on load.** Whether loading a `.json` target keeps the file's key order.
  [formatter](features/formatter.md#open-questions)

## Interactive use

- **irak navigation.** Where indices appear in mixed YAML previews, and what TAB offers
  after `->`. [irak](features/irak.md#5-open-questions-and-design-decisions)

## Implementation

- **Does a `.rak` file compiled by the plain RakuAST frontend stay rak?** Settling this
  unblocks removing the rak code from `src/Raku/*`. [status](status.md#cleanup-still-to-do)
