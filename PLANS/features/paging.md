# Paging

irak [pages](../../GLOSSARY.md#paging) long output: instead of scrolling it past, irak
hands it to a pager, and once the pager quits leaves a two-line summary at the prompt.

```
[3] > <api.github.com/repos/rakudo/rakudo
[4] > .
JSON · 112 lines · 5.3 kB
{
[5] > !p                                  # page it again
```

## Decisions

- **What is paged.** What the irak submission prints through `$*OUT` (`say`, `print`, the
  [formatter](formatter.md)), and the value irak shows. External commands write to the
  terminal directly and are never paged: they may be interactive (`vim`, `top`) or page
  themselves (`git log`). Write `| ^less` for those.
- **What is long.** More than 5 lines or the terminal's height, whichever is smaller,
  counting wrapped lines.
- **Escapes.** Colors (SGR) and hyperlinks (OSC 8) reach the pager unchanged; the
  default pager is `less -R`. OSC 133 prompt marks belong around the prompt, not in the
  paged text.
- **Which pager.** `RAK_PAGER`, else `PAGER`, else `less -R`. An empty `RAK_PAGER` turns
  paging off. irak pages only when its output is a terminal; a `.rak` file never pages.
- **Holding output.** irak holds what a submission prints until it ends, so it can
  measure it. It stops holding, prints what it held and lets the rest through, unpaged,
  as soon as the submission has run for 1 s, flushes `$*OUT` (as `prompt` does), or
  starts an external command that writes to the terminal. Slow output is then seen as
  it comes, and a question printed before reading standard input shows within 1 s.
- **The summary.** Line 1, dimmed: `<format> · <N> lines · <size>`. The format is `JSON`
  for the formatter's output, the value's type when irak shows a value, else what
  `file -b` says about the text. Line 2: the first 80 columns of the first non-blank
  line, colors kept, ending in `…` when cut.
- **`!p`** pages the last output again, whether it was paged or not. With paging off, it
  says so.
- **Errors** are printed in full, never paged, after the output. **`$*ERR`** (warnings,
  `note`) is not held: it stays live and on screen.
