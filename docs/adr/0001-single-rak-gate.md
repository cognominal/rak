# One gate for all rak features: the `.rak` file extension

Every rak feature (naked strings, dotty subscript, new sigils, redirection) activates only
when the source file name ends in `.rak`. The compiler decides once per compilation unit
and exposes the answer as a single dynamic variable that each feature's grammar rule
asserts on. We chose one combined gate over the per-feature flags the original branch
plans proposed (a `$*REDIRECTION-SYNTAX` next to a `$*NEW-DOTTY-SEMANTICS`) because
features that ship together are always wanted together, and because the file extension is
the only boundary a reader can see.

## Considered Options

- **Per-feature dynamic variables.** Rejected: two flags can disagree inside one
  statement (a redirection whose target is spelled with the dotty subscript), and each
  extra flag is another branch the parser has to keep consistent.
- **A separate `rak` grammar and actions pair.** Not rejected — where rak's syntax lives is
  a separate decision, recorded in
  `docs/adr/0003-rak-keeps-its-own-grammar-and-actions.md`. Either way the `.rak` extension
  is the gate this ADR is about.

## Consequences

- A new rak feature is expected to be reachable from the same gate; a second gate needs
  its own ADR.
- The gate is per compilation unit and belongs to whatever frontend compiles it. The shared
  pair derives it from the extension today; per
  `docs/adr/0003-rak-keeps-its-own-grammar-and-actions.md` the fork must derive the same
  gate rather than hardcode it, so a `.rak` file that `use`s a `.rakumod` still does not
  drag the module into rak semantics.
- `-e`, STDIN and the REPL have no file extension to read, so they fall back to
  `RAKU_RAK_MODE`, which the `rak` wrapper sets. That environment variable is the only
  place where rak mode comes from something other than the file name.
