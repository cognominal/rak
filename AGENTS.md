# AGENTS.md

This worktree is the `rak` branch of a rakudo/rakudo fork: a `.rak`-extension-gated
frontend (naked strings, dotty sigil sugar, shellish redirection). Two frontends are built
side by side: `src/Raku/{Grammar,Actions}.nqp` (`Raku::*`) for plain Raku, and
`src/Rak/{Grammar,Actions}.nqp` (`Rak::*`) for rak — a regenerated twin of the Raku pair
that carries the same `$*RAK-SEMANTICS` gates. The rak frontend is selected by
`RAKUDO_RAK_FRONTEND=1 RAKU_RAK_MODE=1`, or by the `./rak` wrapper at the repo root,
which sets those and execs `rakudo-m`. Branch design docs live in `PLANS/`;
`PLANS/SUMMARY.md` is the index.

## Build and test

```bash
perl Configure.pl --gen-moar --gen-nqp --backends=moar --prefix="$PWD/install"
make -j"$(nproc)"                       # ~7 min cold, ~50 s after a src/Raku/*.nqp edit
make rak-test                           # all rak-specific tests (t/*/rak/)
./rak -Ilib t/14-redirection/rak/001-basic.rak  # one .rak test, via the wrapper
RAKUDO_RAKUAST=1 ./rakudo-m -Ilib t/14-redirection/rak/007-gating.raku
```

Rak-specific tests live in a `rak/` subfolder of the test group they belong to,
numbered from the most basic to the most complex (`001-`, `002-`, …).
`make rak-test` runs every `t/*/rak/` file: `.rak` and `.t` through the `./rak`
wrapper, `.raku` gating tests against the plain frontend. `t/harness6` skips
`rak/` folders, so `make test` does not run them.

`--with-nqp=/path/to/installed-nqp` is rejected ("could not get backend information"), so
the build fetches and builds nqp and MoarVM itself. Test files need `-Ilib` for `Test`.

The Rak pair started as `sed 's/Raku::/Rak::/g'` over the Raku pair, but the two have
diverged: rak-only syntax (e.g. naked-string juxtaposition: `f foo bar` passes two
arguments) lives only in `src/Rak/*`. Never regenerate the Rak pair with that sed; port
upstream `src/Raku/*` changes into it by hand, and put rak features in `src/Rak/*` only. The pair's
build rules live in `tools/templates/Makefile-backend-common.in`, so re-running
`Configure.pl` keeps them. Watch for stale concatenations: changing a `_SRC` variable in the
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

Single-context: `GLOSSARY.md` at the root plus `docs/adr/`. See `docs/agents/domain.md`.
