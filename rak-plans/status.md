# Status

What exists on the `rak` branch and what is planned. The per-feature status is in
[features/README.md](features/README.md); this page records the implementation and test
summary. For test results, run `make rak-test` (see `CLAUDE.md`): counts are not recorded
here, because they go stale.

## Implemented

| Feature | Design | Tests |
|---|---|---|
| The `.rak` gate (`$*RAK-SEMANTICS`) and the `./rak` wrapper | [ADR 0001](../docs/adr/0001-single-rak-gate.md) | `*-gating.raku` |
| The separate rak frontend (`src/Rak/*`) | [ADR 0003](../docs/adr/0003-rak-keeps-its-own-grammar-and-actions.md) | — |
| Naked strings, juxtaposed words as arguments | [naked strings](features/naked-strings.md) | `t/02-rakudo/rak/007-*` |
| Spacing decides `>`, `>>`, `<` | [spacing](features/spacing.md) | `t/14-redirection/rak/003-*` |
| The `~` and `#` sigils | [sigils](features/sigils.md) | `t/02-rakudo/rak/002-*`, `003-*` |
| Dotty subscripts, quoted keys, `->name`, `->$var` | [dotty subscripts](features/dotty-subscripts.md) | `t/02-rakudo/rak/001-*`, `004-*`–`006-*`, `008-*`, `013-*`–`016-*` |
| Redirection `>`, `>>`, `<`, loads, `.json` / `.jsonl` formats | [redirection](features/redirection.md), ADRs 0002 and 0004 | `t/14-redirection/rak/` |
| URL targets: GET loads, POST output redirection, `X::Rak::HTTP` | [URL targets](features/url-targets.md), ADR 0005 | `t/14-redirection/rak/013-*`, `014-*` |
| Bare hosts: `<api.github.com/…` loads https | [URL targets](features/url-targets.md) | `t/14-redirection/rak/015-*` |
| irak: the topic, the banner | [irak](features/irak.md) | `t/02-rakudo/rak/010-*`, `012-*` |
| Commands: routines and external commands, `$?`, `cd`, `type` | [commands](features/commands.md) | `t/15-commands/rak/` |
| Pipelines: commands and rak stages, `$?` pipefail, `@?` | [pipelines](features/pipelines.md) | `t/16-pipelines/rak/` |
| The formatter, a lone `.` | [formatter](features/formatter.md) | `t/16-pipelines/rak/006-*`, `007-*` |
| irak history: `!n` re-runs, `!!n` recalls a value | [irak history](features/irak-history.md) | `t/02-rakudo/rak/020-*` |
| irak shows a non-zero exit status | [irak](features/irak.md) | `t/02-rakudo/rak/021-*` |
| irak paging, `!p` | [paging](features/paging.md) | `t/02-rakudo/rak/022-*` |
| irak shows JSON loads as `.` does | [formatter](features/formatter.md) | `t/02-rakudo/rak/024-*` |
| irak's web log, `@*IWEB` | [URL targets](features/url-targets.md) | `t/02-rakudo/rak/025-*` |
| irak `- ` keeps the topic | [irak](features/irak.md) | `t/02-rakudo/rak/023-*` |
| irak highlights the input line, a terminal cheat sheet | [highlight](highlight.md) | `t/02-rakudo/rak/026-*`, `027-*` |
| irak OSC 133 prompt marks | [irak](features/irak.md#shell-integration-osc-133-marks) | `t/02-rakudo/rak/028-*` |
| irak's line editor bundled, core modules compile under the rak frontend | [AUR](build/AUR.md#the-line-editor-is-part-of-the-package) | `t/02-rakudo/rak/018-*`, `019-*` |
| The `rak-git` AUR package (not submitted) | [AUR](build/AUR.md) | — |
| rak versions (`RAK_VERSION`, `v*` tags), release tarball, `rak` package (local) | [release](build/release.md) | `t/02-rakudo/rak/011-*`, `012-*` |
| One-pass CORE setting, `#COMPILER::` directives | [one-pass compilation](build/onepass-compile.md) | the build itself |

How rak differs from Rakudo, and its dependencies, are in
[architectural-note.md](architectural-note.md).

Known gaps, marked `todo` in the sigil tests: `has ~.x` / `has #.x` attributes, and
autoboxing for `~s.WHAT` / `#n.WHAT`. `where` and `state` do not work on `~` and `#`
variables.

## Planned

- The shell strategy: `alias`
  ([strategies](features/strategies.md)).
- Naked-string escapes, interpolation and globbing.
- [Indentation](features/indentation.md) in place of braces, and
  [tree expressions](features/tree-exprs.md).
- One-letter variables without a sigil.
- More redirection operators (`2>`, `&>`, here-documents) and stacking.
- The [GitHub demo](demos/github.md); PATCH, PUT, DELETE and pagination for
  [URL targets](features/url-targets.md).
- YAML, TOML and [myaml](features/myaml.md).
- TAB / SHIFT-TAB data navigation in irak.

Open design questions, such as a `^` sigil for native `num`, are in
[unsettled.md](unsettled.md).

## Cleanup still to do

The rak frontend now lives in `src/Rak/*`, but the rak code has not yet been stripped
out of `src/Raku/*`: `$*RAK-SEMANTICS`, `statement-mod-redir`, `after-ws`, the dotty
name sugar, the `!$*RAK-SEMANTICS ||` guards, `term:sym<rak-string>`, the `~` and `#`
sigils, the tightened `comment:sym<#>`, the escape handlers and the `i1`/`t1` roles. This
waits on deciding whether a `.rak` file compiled through a plain `RAKUDO_RAKUAST` run
must keep parsing as rak.
