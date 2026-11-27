# How rak differs from Rakudo

rak is a fork of Rakudo, the reference Raku compiler. This note says where the
fork's code sits, what it changes in Rakudo and what it adds, and which software
rak needs that Raku and Rakudo Star don't provide. What each feature does is in the
[feature documents](README.md#features), and what exists so far is in
[status.md](status.md).

## One compiler, two frontends

rak is not a module or a slang on top of an installed Rakudo. It is a Rakudo build
with a second parser frontend compiled in:

- `src/Raku/{Grammar,Actions}.nqp` (`Raku::*`) is the RakuAST frontend. It is
  upstream's, plus the `$*RAK-SEMANTICS` gates left from before the split, still to
  be stripped out (see [Cleanup](status.md#cleanup-still-to-do)).
- `src/Rak/{Grammar,Actions}.nqp` (`Rak::*`) is the rak frontend. It started as a
  copy of the Raku pair and now holds all of rak's syntax. It is kept in step with
  upstream by hand-porting the changes made to `src/Raku/*`
  ([ADR 0003](../docs/adr/0003-rak-keeps-its-own-grammar-and-actions.md)).

Both pairs produce the same RakuAST, and the AST nodes, the CORE setting, MoarVM and
NQP are shared. So rak code and Raku code run on the same objects and can call each
other's modules.

`src/main.nqp` picks the frontend at startup:

| Condition | Frontend |
|---|---|
| `RAKUDO_RAK_FRONTEND=1` | `Rak::*` |
| `RAKUDO_RAKUAST=0` | legacy |
| otherwise | `Raku::*` |

The legacy frontend is `src/Perl6/*`. Upstream made RakuAST the default in
November 2026, and rak follows.

Inside the rak frontend, rak semantics stay off until something turns them on
([ADR 0001](../docs/adr/0001-single-rak-gate.md)): a `.rak` or `.rakmod` file extension
(`src/Perl6/Compiler.nqp` records the file name for this), or `RAKU_RAK_MODE=1`. A
`.raku` file parsed by the rak frontend is still plain Raku.

The `./rak` wrapper at the repo root, and `/usr/bin/rak` in the AUR package, set
both variables and exec `rakudo`. With no file argument they start irak, the
interactive mode of the REPL.

## What is changed in Rakudo

### The compiler

- **`src/main.nqp`**: the frontend selection above. It also binds the chosen
  grammar and actions as HLL symbols, so that `EVAL` and the REPL reuse them.
- **`src/Raku/ast/`**: the `~` and `#` sigils. These are native `str` and `int`
  variables with no container (see [sigils](features/sigils.md)).
  `container.rakumod` decides whether a sigil can be native and which type it
  implies. `simple-declaration.rakumod` forces that type and rejects an explicit
  type or container base type. Because the AST is shared, this code is in the
  common tree, not in `src/Rak/`.
- **`src/core.c/Exception.rakumod`**: the new errors, such as
  `X::Syntax::Variable::SigilImpliesType`.

### The build

- **One-pass CORE setting** ([one-pass compilation](build/onepass-compile.md)).
  - In `.rakumod` files, backend directives are written as `#COMPILER::if moar` /
    `#COMPILER::endif` instead of `#?if moar`, and the JVM and JS branches are
    deleted. `.nqp` files keep `#?if`.
  - `tools/build/gen-cat.nqp` accepts both forms.
  - The conversion scripts are in `tools/build/convert-to-compiler-directives.raku`
    and `clean-vestigial-backend-directives.raku`.
  - Most of the large diffs in `src/core.c/` against upstream come from this
    conversion, not from behavior changes. It is also the main source of merge
    conflicts with upstream.
- **`tools/templates/Makefile-backend-common.in`**
  - It compiles and links the Rak pair beside the Raku pair.
  - It installs irak's line editor (see [Dependencies](#dependencies)).
  - It generates `rak-build-info.nqp` (`tools/build/gen-rak-build-info.pl`), which
    gives the irak banner the repository URL and the HEAD commit.
  - Re-running `Configure.pl` keeps these rules.
- **`make rak-test`** runs the rak tests, which live in `t/*/rak/`.
  `t/harness6` skips those folders, so `make test` is upstream's suite unchanged.

### Version pins

`tools/templates/NQP_REVISION` follows upstream Rakudo, which pins NQP, which pins
MoarVM. rak needs no changes of its own in NQP or MoarVM. Fixes found while working
on rak are sent upstream, and rak bumps its pins to pick them up (for example
nqp#882 and MoarVM#2087).

## What is added

### The CORE setting

- **`src/core.c/Rakudo/Internals/RakFormat.rakumod`** is the runtime of rak's
  shell features:
  - redirection to and from files, with the `.json` and `.jsonl` formats
    ([redirection](features/redirection.md));
  - URL targets: GET when loading, POST when redirecting output, the
    `X::Rak::HTTP` error and the web log ([URL targets](features/url-targets.md));
  - pipelines that mix external commands with rak stages, and `$?` / `@?`
    ([pipelines](features/pipelines.md));
  - the formatter, a lone `.` ([formatter](features/formatter.md)).
- **`src/core.c/REPL.rakumod`** gets irak:
  - the topic and `- ` to keep it ([irak](features/irak.md));
  - the banner, the history file `$XDG_STATE_HOME/rak/history` and the startup file
    `$XDG_CONFIG_HOME/rak/init.rak` ([startup file](features/startup-file.md));
  - `!n` / `!!n` recall ([irak history](features/irak-history.md));
  - paging ([paging](features/paging.md));
  - input-line highlighting ([highlight](highlight.md));
  - `@*IWEB`;
  - OSC 133 prompt marks;
  - multi-line input that keeps reading while the code is incomplete.

  Plain `raku` REPL behavior is unchanged unless irak is on.
- **`src/core.c/REPL-COMPLETIONS.rakumod`** is a TAB completer that knows what the
  cursor is on: an identifier, a sigiled variable, a dotty subscript or a method.
- **`src/core.c/REPL-INSPECTOR.rakumod`** previews data structures as YAML.

### Tools, docs and packaging

- **`rak`** is the wrapper at the repo root.
- **`tools/rak-cheatsheet.raku`** renders the terminal cheat sheet,
  `rak-docs/CHEATSHEET.ans`.
- **`tools/update-tlds.raku`** refreshes the top-level domain list that lets a bare
  host such as `api.github.com/…` be read as a URL.
- **`packaging/aur/rak-git/`** is the AUR package ([AUR](build/AUR.md)). It
  installs everything under `/usr/lib/rak`, so it coexists with a system Rakudo.
  `packaging/aur/rak/` builds a release the same way, from its tarball.
- **Versions**: `RAK_VERSION` holds rak's own version (`0.0.1`); `VERSION` stays
  Rakudo's. Releases are `v*` tags, with a self-contained tarball made by
  `tools/build/rak-dist.sh` ([Cutting a release](build/release.md)). The irak banner
  and `rak --version` show the version.
- **Docs**:
  - `rak-plans/` holds the design documents;
  - `rak-docs/` holds the reader documentation and tutorials;
  - `GLOSSARY.md` and `docs/adr/` hold the terms and the decisions;
  - `AGENTS.md` / `CLAUDE.md` hold the instructions for agents.

## Dependencies

### Raku modules

irak needs a line editor: it gives history and editing, and TAB
[completion](features/completion.md) will build on it. irak prefers Terminal::LineEditor. The build installs it and its
dependencies into the `vendor` repository, from tarballs pinned by SHA-256 in
`tools/build/rak-line-editor-dists` and downloaded from the zef CDN:

| Distribution | Version | In Star |
|---|---|---|
| Terminal::ANSIColor | 0.14 | yes |
| Terminal::ANSIParser | 0.0.4 | yes |
| Terminal-API | 1.0.5 | no |
| Terminal::Capabilities | 0.0.21 | no |
| Text::MiscUtils | 0.0.13 | no |
| Terminal::LineEditor | 0.0.23 | patched |

Notes on the table:

- "In Star" means listed in the `etc/modules.txt` of
  [rakudo/star](https://github.com/rakudo/star). Three of the six distributions
  are not there.
- Terminal::LineEditor 0.0.23 is in Star, but rak applies
  `tools/build/rak-line-editor-patches/Terminal-LineEditor-0.0.23.patch`. The patch
  adds an `&on-finish` callback, for irak's double Enter, and a time limit on
  terminal queries. It is not yet submitted to japhb/Terminal-LineEditor, so Star's
  copy does not do what irak needs.
- All six are pure Raku. Terminal-API reaches termios through NativeCall, so rak
  mode must be able to compile core's `NativeCall`. This is also why `./rak` puts
  `lib/` on `RAKULIB`.

Optional modules, loaded only when present:

| Module | Used for | In Star |
|---|---|---|
| HTTP::UserAgent | URLs | yes |
| Readline | editing | yes |
| Linenoise | editing | no |

- HTTP::UserAgent is the fallback for URL targets when `curl` is missing. With
  neither, a URL target throws `X::Rak::HTTP`.
- Readline and Linenoise are the line editors the plain REPL already tries, in that
  order. irak falls back to them when Terminal::LineEditor won't load.

rak uses no other module outside core. JSON goes through core's
`Rakudo::Internals::JSON`. YAML, TOML and [myaml](features/myaml.md) are planned
and have no dependency chosen yet.

### External programs

irak requires [fzf](https://github.com/junegunn/fzf): TAB completion shows its
candidates in fzf, with a preview of each value
([ADR 0008](../docs/adr/0008-completion-menus-use-fzf.md)).

None of the others is needed to build or to run plain rak code. Each one turns on a
feature:

| Program | Used for |
|---|---|
| `curl` | URL targets |
| `gh` | GitHub token |
| `less` | irak pager |
| `stty` | terminal size |

- **`curl`** runs every HTTP request, with the arguments passed on stdin
  (`--config -`).
- **`gh`**: with no authorization configured in
  `~/.config/rak/http-headers.json`, requests to `api.github.com` use the output
  of `gh auth token`.
- **`less -R`** is the default pager. `RAK_PAGER`, then `PAGER`, override it, and
  an empty value turns paging off.
- **`stty size`** measures the terminal for paging.
- **External commands in pipelines** are whatever the user runs. rak looks them
  up on `PATH`, like a shell.

### Build time

The build needs:

- Perl 5, for `Configure.pl` and `tools/build/*.pl`;
- git, to fetch NQP, MoarVM and their submodules;
- network access to `360.zef.pm`, for the line editor tarballs.

`rak-line-editor.pl` reuses tarballs already in `gen/rak-dists/`, and it only warns
when it can't download. So a build with no network succeeds, and irak then runs
without a line editor. The AUR package lists the tarballs as sources and builds
offline ([Building offline](build/AUR.md#building-offline)).

The package depends only on `glibc` and `zstd`: MoarVM, NQP and Rakudo are built
from the pinned revisions and bundled, since the AUR's versions are older than the
pins.
