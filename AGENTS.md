# AGENTS.md

This worktree is the `rak` branch of a rakudo/rakudo fork: Rakudo with a second
frontend, `src/Rak/{Grammar,Actions}.nqp` (`Rak::*`), beside upstream's
`src/Raku/{Grammar,Actions}.nqp` (`Raku::*`). The `./rak` wrapper at the repo root
selects it (`RAKUDO_RAK_FRONTEND=1 RAKU_RAK_MODE=1`) and execs `rakudo-m`.

Read [`rak-plans/architectural-note.md`](rak-plans/architectural-note.md) first: how
rak differs from Rakudo, where its code sits (frontends, shared AST, CORE setting,
build rules, tests), and what it depends on outside Raku and Rakudo Star. Design docs
are indexed in `rak-plans/README.md`; reader documentation (cheat sheet, tutorials,
background essays) in `rak-docs/README.md`.

## Build and test

```bash
perl Configure.pl --gen-moar --gen-nqp --backends=moar --prefix="$PWD/install"
make -j"$(nproc)"                       # ~7 min cold, ~50 s after a src/Raku/*.nqp edit
make rak-test                           # all rak-specific tests (t/*/rak/)
./rak -Ilib t/14-redirection/rak/001-basic.rak  # one .rak test, via the wrapper
./rakudo-m -Ilib t/14-redirection/rak/007-gating.raku  # plain frontend (RakuAST)
```

Rak-specific tests live in a `rak/` subfolder of the test group they belong to,
numbered from the most basic to the most complex (`001-`, `002-`, …).
`make rak-test` runs every `t/*/rak/` file: `.rak` and `.t` through the `./rak`
wrapper, `.raku` gating tests against the plain frontend. `make test` does not run
them. Judge a `make test` run against a baseline from the previous build, not
against zero: some upstream test files already fail.

`--with-nqp=/path/to/installed-nqp` is rejected ("could not get backend information"), so
the build fetches and builds nqp and MoarVM itself. Test files need `-Ilib` for `Test`.

The Rak pair started as `sed 's/Raku::/Rak::/g'` over the Raku pair, but the two have
diverged: rak-only syntax (e.g. naked-string juxtaposition: `f foo bar` passes two
arguments) lives only in `src/Rak/*`. Never regenerate the Rak pair with that sed; port
upstream `src/Raku/*` changes into it by hand, and put rak syntax in `src/Rak/*` only.
The `$*RAK-SEMANTICS` gates still in `src/Raku/*` are leftovers awaiting cleanup
(`rak-plans/status.md`); don't add new ones. Semantics shared by both frontends, such
as the `~` / `#` sigils, belong in `src/Raku/ast/` and `src/core.c/`.

Watch for stale concatenations: changing a `_SRC` variable in the
generated `Makefile` and rebuilding without deleting `gen/moar/Raku{Actions,Grammar}.nqp`
compiles the old source into the new path and the link then dies with
`Merging GLOBAL symbols failed: duplicate definition of symbol Actions`.

`gating.raku` must run on the plain frontend: the wrapper's rak-mode environment variable
leaks into its `EVAL`. The `.t` feature tests under `t/02-rakudo/` go through the wrapper
instead, since their rak spellings live in `EVAL` strings.

## Agent skills

### Issue tracker

Issues and specs live as markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` at the root plus `docs/adr/`. See `docs/agents/domain.md`. i

## A commits

A model session has a purpose which is its name. Ask for a  name if the session is unamed. A commit should start with
[purpose state]. State can be one or more of many SPEC WIP FIX

If a commit is unrelated to the session's purpose, don't use the session's name: work
out the purpose that fits the commit, and ask the user when it isn't clear.
