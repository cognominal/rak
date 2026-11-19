# Roadmap

This is a tentative roadmap, not a timeline: it says in which version of rak each
feature is expected to land.

No version has been released yet. I intend to publish 0.1 and later versions on the
AUR. Rakudo itself is not in the official Arch repositories; it is only in the AUR
(`rakudo`, `rakudo-bin`). The current focus
is irak, the interactive rak.

Backward compatibility will not be preserved before 0.5: irak submissions are, by
nature, throwaway scripts.

A version is either marked as done (none is yet), or its features are split into two
lists: DONE and TBD.

- **0.1**: the first released version.
  - DONE: naked strings, jq-like subscripting, redirections.
  - TBD: aliases, web redirections, globbing, recalling and editing previous
    submissions with the up and down arrows.
- **0.2**: ZLE-style completion, a configurable prompt.
- **0.4**: indentation as syntax.
- **0.5**: tooling: LSP support, syntax highlighting.
- **0.6**: a github.io site, and a programming course built with the `/teachme`
  skills that uses irak, rak and agents. It may use Tauri and the tuios API.
