# Completion menus use fzf, a required dependency

When TAB in irak has more than one candidate, irak hands them to fzf, which shows them
under the prompt and previews the value each one leads to (the keys of a hash, the
first elements of an array). fzf is therefore a required dependency of rak, like the
line editor, not an optional program that turns a feature on.
See [completion](../../rak-plans/features/completion.md).

## Considered Options

- **Cycling in place, as Terminal::LineEditor does.** Rejected: it shows one candidate
  at a time and nothing of the values behind them.
- **An inline menu drawn by irak's `IrakEditor` role.** Feasible in about 150 lines, with
  no new dependency. Rejected: previewing each candidate's value is what makes data
  completion useful, and fzf already does the menu, the fuzzy filter and the preview
  pane.
- **fzf only when installed, cycling otherwise.** Rejected: two behaviors to maintain
  and test for one key.

## Consequences

- fzf runs as a separate process, so previews are rendered before it starts and
  written to temporary files; the candidates are capped at 200.
- Packages of rak depend on fzf, and the architectural note lists it among the
  required programs.
