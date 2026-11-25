# Features

Design documents for the features of rak. Each document opens with a status line; this
index gives its one-line definition and status. Highlighting lives in the parent
directory and is included here.

- **WIP** — implemented, or partly implemented, on the branch; the document names the
  missing parts. No version has been released yet.
- **TBD** — not implemented and not assigned to a version. The plan is
  [ROADMAP.md](../../ROADMAP.md).
- **PLANNED <version>** — not implemented; scheduled for that rak version in
  [ROADMAP.md](../../ROADMAP.md).
- **NEEDSPEC** — the specification is incomplete or inconsistent; the document names the
  open questions. It can be combined with another status, most often with PLANNED.

A status covers the feature as a whole: a document may have implemented and TBD parts,
and its status line says which.

| Feature | Definition | Status |
|---|---|---|
| [Aliases](aliases.md) | `alias ll=ls -l`: a name for a command and its first words. | WIP |
| [Commands](commands.md) | Running routines and external commands: `$?`, `cd`, `type`. | WIP |
| [Dotty subscripts](dotty-subscripts.md) | Subscripts without brackets: `%h.users.1.name`, `->meth`. | WIP |
| [The formatter](formatter.md) | A lone `.` shows its input as JSON. | WIP, NEEDSPEC |
| [Highlighting](../highlight.md) | Coloring rak code by what each word denotes, in irak and the terminal cheat sheet. | WIP, NEEDSPEC |
| [Indentation](indentation.md) | Indentation in place of braces. | PLANNED 0.4, NEEDSPEC |
| [irak history](irak-history.md) | `!n` and `!!n` re-run a submission and recall its value. | WIP |
| [irak](irak.md) | The interactive session, its topic `$_`, and TAB / SHIFT-TAB navigation. | WIP, NEEDSPEC |
| [myaml](myaml.md) | YAML literals and pattern matching on data structures. | PLANNED 0.3, NEEDSPEC |
| [Naked strings](naked-strings.md) | Unquoted words as strings. | WIP, NEEDSPEC |
| [Paging](paging.md) | irak pages long output, then leaves a summary. | WIP |
| [Pipelines](pipelines.md) | Unix and jq-style pipes, mixed; `$?` and `@?`. | WIP |
| [Redirection](redirection.md) | Operators, targets, values and stacking. | WIP, NEEDSPEC |
| [The new sigils](sigils.md) | `~` and `#`: native `str` and `int`, no boxing. | WIP, NEEDSPEC |
| [Spacing](spacing.md) | Spacing tells operators from redirections. | WIP |
| [The startup file](startup-file.md) | `init.rak`, and rak's XDG config and state folders. | WIP |
| [Strategies](strategies.md) | The standard and shell strategies, and how a statement is read. | WIP, NEEDSPEC |
| [Tree expressions](tree-exprs.md) | A multi-line expression's layout is its tree. | TBD, NEEDSPEC |
| [URL targets](url-targets.md) | HTTP GET and POST as redirections. | WIP, NEEDSPEC |
