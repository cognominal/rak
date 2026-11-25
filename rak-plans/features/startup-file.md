# The startup file and rak's user folders

Status: WIP — tested by `t/02-rakudo/rak/029-irak-startup-file.t`.

Where rak keeps each user's files, and the [startup file](../../GLOSSARY.md#startup-file)
that the [irak prompt](../../GLOSSARY.md#irak-prompt) runs before the first
[submission](../../GLOSSARY.md#irak-submission). This prepares for aliases: they will be
defined there. The decision and its alternatives are in
[ADR 0006](../../docs/adr/0006-rak-user-files-follow-xdg-on-every-platform.md).

## Spec

### Folders

| Kind   | Folder                  | Holds                |
|--------|-------------------------|----------------------|
| config | `$XDG_CONFIG_HOME/rak/` | `init.rak`, headers  |
| state  | `$XDG_STATE_HOME/rak/`  | `history`            |

- An unset XDG variable means its default: `$HOME/.config`, `$HOME/.local/state`. The
  same on every platform.
- The config folder holds the files the user writes: `init.rak` and `http-headers.json`
  (already read from there by [URL targets](url-targets.md)). The state folder holds
  what rak writes: irak's history.
- The irak prompt creates both folders at startup when they are missing. `-e`, piped
  standard input and `.rak` files create nothing; they only read what exists.
- Nothing is created at install time, and no starter `init.rak` is written.
- A folder that cannot be created costs one warning naming its path; irak then runs
  without saving history. A missing config folder just means no startup file.
- irak's history is `$XDG_STATE_HOME/rak/history`. irak ignores `RAKUDO_HIST`, which plain
  Rakudo's REPL keeps. There are no `RAK_*` override variables.
- `~/.raku/irak-history` is not migrated; the release notes tell users to move it.

### The startup file

- `$XDG_CONFIG_HOME/rak/init.rak`, compiled in [rak mode](../../GLOSSARY.md#rak-mode).
- Only the irak prompt runs it. `-e`, piped input and `.rak` files never do: a script
  that wants shared definitions `use`s a module.
- It is not a submission: it has no number, `!n` cannot recall it, and it leaves `$_`
  alone. The first prompt is still `[0]`.
- What it defines (routines, variables, later aliases) is visible to every submission, as
  an outer scope. What it prints is shown.
- If it fails to compile or throws, irak shows the error with its file and line, then
  starts anyway, with whatever ran before the error.
- `rak --no-init` starts the irak prompt without it. Plain Rakudo rejects the option.
- A program that calls `repl()` opens an irak prompt, which runs the startup file too.

## Out of scope

- Aliases themselves, and [builtins](../../GLOSSARY.md#builtin) written in rak and read
  from the install tree. Both wait on the lookup order of names, still open in
  [unsettled.md](../unsettled.md).
- Data and cache folders (`$XDG_DATA_HOME/rak/`, `$XDG_CACHE_HOME/rak/`), until something
  needs them.

## Implementation notes

- `RAK-XDG-DIR` in `src/core.c/Rakudo/Internals/RakFormat.rakumod` gives both folders;
  `http-headers.json` uses it too. An empty or relative XDG variable counts as unset,
  as XDG says.
- `src/core.c/REPL.rakumod`: `!irak-make-dirs`, `!irak-startup-file` (run from
  `repl-loop`, as a submission would be, but not stored or numbered) and the irak
  branch of `history-file`. A compile error gets the file name stamped on it, since an
  `EVAL`'d source has none and RakuAST ignores `#line`.
- `--no-init` is added to the command-line options in `src/main.nqp` only under the rak
  frontend; `Compiler.usage` lists it.
- `make rak-test` points the XDG variables into `gen/rak-test-xdg/`, so no test runs the
  user's startup file or writes to their history.

## For the next release notes

irak's history moved from `~/.raku/irak-history` to `~/.local/state/rak/history`, with
no migration: `mv ~/.raku/irak-history ~/.local/state/rak/history` keeps it.
