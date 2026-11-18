# 08: A bare `<target` loads into the topic

**What to build:** a statement consisting only of `<target` (no statement after it, nothing
before it) loads the decoded content into `$_`, so a following leading dotty subscript
reaches into it (`<a.json` then `.users.0.name`). In irak the loaded value counts as the
submission's value, so it becomes the irak topic.

**Blocked by:** 07

**Status:** resolved

**Tests:** `t/14-redirection/rak/011-load-topic.rak`, `t/02-rakudo/rak/010-irak-topic.t`

- [X] `<a.json;` followed by `.name` gives the loaded object's `name`.
- [X] Dotty chains reach nested data (`.users.0.name`).
- [X] `<a.json say 1` is still input redirection, not a load.
- [X] In irak, the next submission's `.name` reaches into the loaded data.

## Answer

The statement-start `<target` alternative in `src/Rak/Grammar.nqp` now checks what follows
the target: at `;`, `}` or the end of input it sets `$<load-topic>` instead of parsing a
statement (which previously matched as an empty statement under input redirection). The
statement action builds `$_ = RAK-LOAD(target, '$', '$_')`, reusing 07's runtime, so any
shape is accepted. The assignment's value is the loaded content, so irak's existing
value-based topic picks it up with no REPL change.
`011-load-topic.rak`: 4/4; `010-irak-topic.t`: 10/10 (new test 8 covers irak).
