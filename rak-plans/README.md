# rak-plans

Design documents for rak: how each feature is meant to work, what is implemented, and
what is still open. The documentation for readers, the cheat sheet, the tutorials and
the background essays, is in [rak-docs](../rak-docs/README.md). Terms are defined in
[GLOSSARY.md](../GLOSSARY.md), decisions are recorded in [docs/adr/](../docs/adr/).
Build and test instructions are in `CLAUDE.md`.

## Overview

- [Status](status.md): what is implemented, what is planned, cleanup still to do.
- [Unsettled](unsettled.md): the open design questions, at a glance.
- [Architectural note](architectural-note.md): how rak differs from Rakudo, what it
  changes and adds, and what it depends on outside Raku and Rakudo Star.

## Features

The per-feature status and one-line definitions are in
[features/README.md](features/README.md).

- [Plain and shell syntax](features/syntaxes.md): commands, pipes, `type`.
- [Naked strings](features/naked-strings.md): unquoted words as strings.
- [Spacing as syntax](features/spacing.md): spacing tells operators from redirections.
- [Indentation as syntax](features/indentation.md): indentation in place of braces.
- [Tree expressions](features/tree-exprs.md): the layout of a multi-line expression is
  its tree.
- [The new sigils `~` and `#`](features/sigils.md): native `str` and `int`, no boxing.
- [Dotty subscripts](features/dotty-subscripts.md): `%h.users.1.name`, `->meth`.
- [Redirection](features/redirection.md): planned operators, targets and stacking.
- [URL targets](features/url-targets.md): HTTP GET and POST as redirections.
- [myaml](features/myaml.md): YAML literals and pattern matching on data.
- [irak](features/irak.md): the interactive session.
- [Completion](features/completion.md): TAB completes through fzf, previewing values.
- [irak history](features/irak-history.md): `!n` / `!!n` recall of submissions.
- [atuin](features/atuin.md): record irak submissions in atuin, and import its history.
- [Highlighting](highlight.md): coloring rak code by what each word denotes, in irak
  and in the terminal cheat sheet.
- [Commands](features/commands.md): running routines and external commands, `$?`, `cd`, `type`.
- [Pipelines](features/pipelines.md): Unix and jq-style pipes, mixed; `$?` and `@?`.
- [The formatter](features/formatter.md): a lone `.` shows its input as JSON.
- [Paging](features/paging.md): irak shows long output in a pager, then a summary.

## Demos

- [GitHub](demos/github.md): the GitHub REST API as a showcase for URL targets.

## Build

- [One-pass compilation](build/onepass-compile.md): the CORE setting in one pass,
  `#COMPILER::` directives.
- [AUR](build/AUR.md): the `rak-git` package, its bundled line editor, building offline.
- [Cutting a release](build/release.md): `RAK_VERSION`, the `v*` tags, the release
  tarball (`tools/build/rak-dist.sh`), building from it, the `rak` package.

## Archive

Design logs of the branches merged into `rak`, kept for their history. They are out of
date; the documents above supersede them.

- [new-sigils design log](archive/new-sigils-design.md)
- [new-sigils subscript operator log](archive/subscript-operator.md)
- [redirection design log (RAKFILE)](archive/RAKFILE.md)
- [Tables](features/tables.md): lists of hashes shown as grids, nushell's `ls`,
  filesizes and topical commands.
