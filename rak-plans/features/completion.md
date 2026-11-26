# Completion: TAB in irak

Status: WIP — selectors and `->` methods are implemented; other positions still use
the old word completion, through fzf. Replaces the "Navigating data with TAB and
SHIFT-TAB" design formerly in [irak.md](irak.md).

At the [irak prompt](../../GLOSSARY.md#irak-prompt), TAB completes the word under the
cursor. When more than one candidate fits, irak opens [fzf](https://github.com/junegunn/fzf)
under the prompt; for data, fzf previews the value each candidate leads to. fzf is a
required dependency of rak ([ADR 0008](../../docs/adr/0008-completion-menus-use-fzf.md)).

## Completing a selector

A [selector](../../GLOSSARY.md#selector) is what follows the `.` of a
[dotty subscript](../../GLOSSARY.md#dotty-subscript). With the topic
`{ :key1, :key2, :foo }`:

```
.k█        TAB  →  fzf lists key1, key2
%h.a.1.█   TAB  →  fzf lists the keys or indices of %h.a.1
```

### The subject

The subject is what the selector applies to: `$_` for a leading `.`, `%h.a.1` for
`%h.a.1.k`. TAB never compiles or runs code to get it. irak reads the chain left of the
cursor and walks it itself:

- the chain starts with a variable, or with nothing (the topic);
- each further step is a selector, resolved with `AT-KEY` or `AT-POS`;
- anything else in the chain (a call `foo().k`, a method `->meth.k`, an expression in
  brackets) gives no completion.

So a TAB never fetches a [URL target](../../GLOSSARY.md#url-target), runs an
[external command](../../GLOSSARY.md#external-command) or consumes a lazy `Seq`.

### The candidates

- **Keys.** The subject's keys that start with the typed prefix. A bare identifier only
  matches keys: in rak mode `.k` is a hash subscript, never a method.
- **Indices.** When the subject is positional, its indices. With digits typed (`.12`),
  the indices that start with them, across the whole range.
- **Both.** A subject with keys and indices (a `Match`) offers its keys after letters,
  its indices after digits, and both after a bare `.`.
- **Quoting.** A key that is not a valid dotty identifier (`foo bar`, `1x`, `12`) is
  inserted as `.'foo bar'`. Inside `.'` or `."`, the prefix matches the raw key.
- **Limit.** At most 200 candidates. fzf's header gives the real size, such as
  `Hash · 3 keys` or `Array · 0..9999 · showing 200`.

### What TAB replaces

The chosen candidate replaces the whole selector under the cursor, including what is
right of the cursor, up to the next `.`, `->`, bracket, whitespace or `)`. The rest of
the chain stays: in `%h.k█ey9.foo`, choosing `key1` gives `%h.key1.foo`.

Terminal::LineEditor's own completion only replaces the text left of the cursor, so
irak's `IrakEditor` role binds TAB to its own action, as it does for Ctrl-R.

## fzf

- **When it opens.** One candidate is inserted without opening fzf; none leaves the
  buffer unchanged. The options are
  `--height=40% --layout=reverse --query=<prefix> --select-1 --exit-0
  --preview-window=right,60%`. `FZF_DEFAULT_OPTS` applies, as fzf reads it itself.
- **The terminal.** irak leaves raw mode while fzf runs, as for atuin, then redraws the
  prompt with the new buffer. Esc in fzf leaves the buffer unchanged.
- **Previews.** Before fzf starts, irak writes each candidate's value to a file in a
  temporary directory, as YAML from `REPL::DataInspector` at depth 2, and fzf shows
  it with `--preview 'cat DIR/{1}'`. For an array, the preview of an index is its
  element.
- **Missing fzf.** TAB says `irak: fzf not found`. There is no cycling fallback.

## Other positions

Every TAB goes through fzf, one position at a time after selectors:

1. **Methods after `->`.** `->el█` lists the subject's methods; the preview shows
   their signatures. The subject is found as for selectors.
2. **Variables, identifiers, `use` and types,** which `REPL-COMPLETIONS.rakumod`
   already recognises.
3. **Commands and their arguments** in the
   [shell strategy](../../GLOSSARY.md#shell-strategy): aliases, routines, builtins and
   `$PATH`, then file paths, then
   [redirection targets](../../GLOSSARY.md#redirection-target).

## Scope

- Only irak: the plain `raku` REPL keeps its completion, as the
  [architectural note](../architectural-note.md) requires.
- No SHIFT-TAB for now: the fzf preview shows what is under each candidate. A later
  SHIFT-TAB could open fzf on the subject's whole tree, with paths such as `.a.1.name`
  as candidates.
- No editor integration (LSP, `rak --complete`), but finding the site and the
  candidates stays independent of the line editor, so it can be reused.

## Tests

`t/02-rakudo/rak/033-irak-complete.t` tests the engine directly: for a line and a
cursor position, the subject chain, the candidates, the range replaced, the quoting
and the YAML preview. Sessions under script(1) then press TAB with a fake `fzf` on
`PATH`, which logs its arguments and previews and picks a candidate. A smoke test
runs the real fzf with `--filter`.
