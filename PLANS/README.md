# PLANS

Design documents for rak. Terms are defined in [GLOSSARY.md](../GLOSSARY.md), decisions
are recorded in [docs/adr/](../docs/adr/), and usage is in
[CHEATSHEET.md](../CHEATSHEET.md). Build and test instructions are in `CLAUDE.md`.

## Overview

- [rak](rak.md): what rak is and why.
- [Status](status.md): what is implemented, what is planned, cleanup still to do.
- [Unsettled](unsettled.md): the open design questions, at a glance.

## Features

- [The standard and shell strategies](features/strategies.md): commands, pipes, `type`.
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
- [irak](features/irak.md): the interactive session, and TAB / SHIFT-TAB navigation.
- [irak history](features/irak-history.md): `!n` / `!!n` recall of submissions.
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

## Background

Essays on where rak comes from. Written with the help of DeepSeek.

- [A short history of shells](background/shells.md), from RUNCOM to Nushell.
- [Terminals](background/terminals.md), from Teletypes to Herdr, and charmbracelet.
- [Perl](background/perl.md): from duct tape to solipsism.
- [rak and the Perl Power Tools](background/perl-power-tools.md).
- [Larry Wall, natural language and pragmatics](background/larry-wall.md).
- [Huffing](background/huffing.md): rak and the Huffman principle.

## Archive

Design logs of the branches merged into `rak`, kept for their history. They are out of
date; the documents above supersede them.

- [new-sigils design log](archive/new-sigils-design.md)
- [new-sigils subscript operator log](archive/subscript-operator.md)
- [redirection design log (RAKFILE)](archive/RAKFILE.md)
