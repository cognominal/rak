# Rak keeps its own grammar and actions pair

Rak's syntax belongs in `src/Rak/Grammar.nqp` and `src/Rak/Actions.nqp`, a namespaced fork
of the RakuAST frontend, not in rak-shaped branches threaded through
`src/Raku/Grammar.nqp`. The shared pair serves plain Raku; the fork is where the rak
dialect lives and grows. The `.rak` file extension stays the boundary for what a
compilation unit means (ADR-0001), so whichever pair a process loads still has to tell
`.rak` from `.rakumod` and `.raku`.

## Considered Options

- **Gated alternatives inside the shared grammar** — rak branches sitting next to the
  standard ones behind `<?{ $*RAK-SEMANTICS }>`, which is what actually runs today.
  Rejected as the destination: every rak feature becomes a second alternative inside a
  token owned by the other language, so neither dialect can be read on its own. Kept only
  as the interim until the fork is loaded.
- **A fork with rak semantics unconditional.** Rejected: everything a rak process compiles
  would be rak, including `.rakumod` modules. Measured against the old snapshot, which
  hardcoded `$*RAK-SEMANTICS := 1` (`src/Rak/Actions.nqp:428`, `src/Rak/Grammar.nqp:1361`):
  a `.raku` file whose source says `$a <$b` compiled under the shared pair and failed with
  `Confused` under `RAKUDO_RAK_FRONTEND=1`. The pair that ships keeps the gate instead, so
  the same line in a `.rakumod` compiles and in a `.rak` file does not.

## Consequences

- Two frontends are built side by side (`blib/Raku`, `blib/Rak`). The Rak pair is a
  *regenerated twin*: `sed 's/Raku::/Rak::/g'` over the shared sources, the rename being the
  only difference that mattered (66 diff lines in Grammar, 155 in Actions, all of them gates
  and the gate's own plumbing). It carries the same gates and the same features, redirection
  included, so it must be regenerated whenever `src/Raku/*` changes — until the two are meant
  to diverge, at which point it stops being a copy.
- Wiring lives in `tools/templates/Makefile-backend-common.in`, so a re-run of
  `Configure.pl` keeps it: `BLIB_RAKUDO_RAK`, `RAKUDO_{G,A}_RAK`, `RAKUDO_{G,A}_RAK_SRC`,
  `RAKUDO_PRECOMPS_RAK`, the gen-cat and compile rules, the `rakudo.moarvm` prerequisites,
  the `make clean` list and the `<lib>/Rak` install copy, plus `blib/Rak/.gitignore` so the
  directory exists before anything is written into it. `src/main.nqp` loads both pairs, picks
  `Rak::*` behind `RAKUDO_RAK_FRONTEND` and binds it as the `Raku` HLL grammar; the `rak`
  wrapper exports that variable together with `RAKU_RAK_MODE=1`.
- **Delete `gen/moar/Raku{Actions,Grammar}.nqp` whenever the source variables in the
  `Makefile` change.** The generated file is newer than the new prerequisite, so `make`
  re-uses the old concatenation and compiles it into the new path; the link then dies with
  `Merging GLOBAL symbols failed: duplicate definition of symbol Actions`, because the same
  unit is merged twice under two names. That artefact, not an NQP limitation, is why the
  fork was previously written off as failing to compose — the earlier account blamed
  `create-quote-lang-type`, which lives in the grammar and was never reached.
- Coexistence is measured, not assumed: with the fork built from corrected sources,
  `blib/Rak/Actions.moarvm`, `blib/Rak/Grammar.moarvm` and `rakudo.moarvm` build and link
  together, `use Raku::Actions; use Rak::Actions;` (and both grammars) merge cleanly, and
  `Raku::Grammar` and `Rak::Grammar` are distinct types.
- The fork derives the gate from the file extension in its own `comp-unit-prologue`, copied
  from the shared pair, so a `.rakumod` module compiled inside a rak process keeps standard
  parsing: `Mod.rakumod` containing `$a <$b` compiles and returns `True`, while the same line
  in a `.rak` file fails with `Confused`.
- Verified through the wrapper: the live pair is observable
  (`nqp::gethllsym('Raku','Grammar')` names `Rak::Grammar`, and `Raku::Grammar` on the plain
  frontend), all six `t/14-redirection/*.rak` files pass with no failures, `gating.raku` is
  3/3 against the plain frontend, and `t/02-rakudo/new-sigil-int.t` is still 16/18 — the
  known pre-existing shortfall.
- Rak syntax is still in `src/Raku/*` as well. Stripping it there (12 `RAK-SEMANTICS` sites
  in `Grammar.nqp`, 3 in `Actions.nqp`) waits on deciding whether a `.rak` file compiled
  through a plain `RAKUDO_RAKUAST` invocation must keep parsing as rak. Today it does,
  because the gate is extension-derived on both sides.