# rak's per-user files follow XDG on every platform, apart from Raku's

rak keeps each user's files where the XDG Base Directory conventions put them, on every
platform, macOS and Windows included: what the user writes (the
[startup file](../../GLOSSARY.md#startup-file), `http-headers.json`) in
`$XDG_CONFIG_HOME/rak/`, and what rak writes (irak's history) in `$XDG_STATE_HOME/rak/`.
An unset variable means its XDG default, `~/.config` or `~/.local/state`. rak lines are
not Raku, so rak's files leave `~/.raku` and stop following Raku's conventions: irak
ignores `RAKUDO_HIST`, and rak adds no `RAK_*` variables of its own. The XDG variables
are the only knobs, and tests point them at a temporary directory.

The folders are made when the [irak prompt](../../GLOSSARY.md#irak-prompt) starts and
finds them missing, never at install time: a package installs as root and cannot know
the users, nor those created later. `-e`, piped input and `.rak` files make nothing in
the home directory.

## Considered Options

- **Everything in `~/.config/rak/`.** Rejected: the history file changes with every
  session, and it would churn in a dotfiles repository that holds `~/.config`.
- **Each platform's native location** (`~/Library/Application Support` on macOS,
  `%APPDATA%` on Windows). Rejected: one layout to document, and the one most command-line
  tools (git, fish, helix) already use on macOS.
- **Keep `~/.raku/irak-history` and `RAKUDO_HIST`.** Rejected: it ties rak to Raku's
  conventions, for a file that Raku's REPL could not read anyway.
- **Create the folders when installing.** Rejected: impossible from a system package.

## Consequences

- Users of rak 0.0.1 keep their history only by moving `~/.raku/irak-history` to
  `~/.local/state/rak/history` themselves: there is no migration, and the release notes
  say so.
- A folder that cannot be made (a read-only home) costs one warning naming its path, and
  irak runs without saving history.
