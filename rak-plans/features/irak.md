# irak: the interactive session

Status: WIP, NEEDSPEC — the topic, `- `, banner, line editor and OSC 133 are
implemented; pinning the topic (lone `-`, `! `) and TAB / SHIFT-TAB navigation are not
(see § Pinning the topic and § Navigating data with TAB and SHIFT-TAB).

[irak](../../GLOSSARY.md#irak) is rak with no source file: the REPL, `-e` and standard input.
The `./rak` wrapper with no arguments starts it. Usage is in the
[cheat sheet](../../rak-docs/CHEATSHEET.md#irak-the-repl); this document covers the design, and the
planned TAB / SHIFT-TAB navigation of data structures.

## irak: the REPL as a pipe through time

In [irak](../../GLOSSARY.md#irak), the [irak topic](../../GLOSSARY.md#irak-topic) `$_` holds the value of the previous [irak
submission](../../GLOSSARY.md#irak-submission), so each submission works on the output of the one before.
This is the interactive habit of growing a pipeline one stage at a time,
but the values passed between stages stay structured.

### When a submission updates the topic

A submission updates the topic when the topic is unpinned and its value is shown: its
value becomes `$_`. Loading with `<file` (nothing on its left) also counts.

A submission whose output comes from commands updates the topic too: the
[external commands](../../GLOSSARY.md#external-command) it runs at statement level
write to the terminal as before, and what they wrote to standard output, as one `Str`
with its final newline removed, becomes `$_`. `ls` then `.lines.elems` counts the
files. Its `Proc` is not shown and is not the topic.

- Standard error is shown but not kept.
- The exit status does not matter: `grep` that exits 1 after printing lines still sets
  the topic. A command that writes nothing to standard output leaves `$_` alone.
- When several commands write, their outputs are joined in the order they ran.
- When Raku code in the same submission also prints (`say`), the output is not all
  from commands and `$_` is left alone.

A submission leaves `$_` alone when:

- it fails, or its value is `Nil`;
- Raku code in it prints output itself (`say`, `print`), so its value is not shown;
- it is the formatter `.`, which shows JSON;
- it is a [topic-keeping submission](../../GLOSSARY.md#topic-keeping-submission);
- the topic is [pinned](../../GLOSSARY.md#pinned-topic) and the submission is not a
  [topic-setting submission](../../GLOSSARY.md#topic-setting-submission).

In every case the value is still recorded, so `!!n` can make it the topic later; for a
submission of commands, the value recorded is their output.

Open: keeping a command's output means irak sits between the command and the terminal.
The command must still see a terminal, or `ls` stops using columns and colors and
full-screen programs (`vim`, `less`, `top`) break, so irak would run it on a
pseudo-terminal and copy its output through. What a full-screen program writes is
screen drawing, not output: irak should not keep it, for instance when the program
switches to the alternate screen. Whether to cap the size of the kept output is
also open.

### Pinning the topic

A lone `-` on the line of a fresh submission is not a submission: it toggles the pin.
It pins the topic when it is unpinned and unpins it when it is pinned. It gets no
number, runs nothing, and `!n` cannot recall it; irak answers `irak: topic pinned` or
`irak: topic unpinned`.

While the topic is pinned, submissions run and show their values as usual, but `$_`
stays the value it had when it was pinned, so one value can be explored at length
without `- ` on every line. Two things still change it:

- a topic-setting submission, `! ` before the submission (see below);
- `!!n`, which sets `$_` to the value of submission `n`. The pin stays on, now
  holding that value.

A session starts unpinned. The pin is not saved between sessions.

### Prefixes for one submission

Two prefixes act on one submission. Each counts only at the start of a fresh
submission, not on a continuation line; it is stripped before the submission runs and
kept in its recorded source, so `!n` replays it with the same effect and `!n` TAB
shows it.

- `- ` makes a topic-keeping submission: its value does not become `$_`, pinned or not.
  `- ls` shows the listing and keeps the topic.
- `! ` makes a topic-setting submission: its value becomes `$_` even while the topic is
  pinned. The pin stays on, now holding the new value. Unpinned, `! ` changes nothing.
  The other rules still apply: a failure, `Nil`, or a submission that prints its own
  output leaves `$_` alone even with `! `.

Only the automatic update depends on these: `- $_ = 3` and an assignment to `$_` while
pinned still assign.

Two Raku spellings lose their meaning at the start of an irak submission: prefix minus
followed by a space (`- 5`, write `-5`) and prefix negation followed by a space
(`! $x`, write `!$x`). A lone `-` was a syntax error, so the toggle takes nothing away.


## Line editing

irak edits with Terminal::LineEditor, whose input line is one scrolling row as wide as
the terminal was when the prompt appeared. irak adds terminal resizes: on SIGWINCH the
line is redrawn at the new width, keeping its text and cursor, and history recall uses
that width too. A terminal that reflows the old row may leave a fragment of it above
the redrawn prompt.

## Shell integration: OSC 133 marks

Status: **done** (`src/core.c/REPL.rakumod`, test
`t/02-rakudo/rak/028-irak-osc133.t`).

irak marks its prompts and outputs with the
[OSC 133](https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md)
semantic prompt sequences, as zsh, fish and bash do with their shell integration.
Terminals that read them (kitty, WezTerm, Ghostty, iTerm2, foot, VS Code) can then jump
from prompt to prompt, select a submission's output, and flag the submissions that failed.

| mark | sent |
|---|---|
| `A` | before the prompt |
| `B` | after the prompt |
| `C` | before the output |
| `D;n` | after the output |

Each mark is `ESC ] 133 ; <mark> ESC \`.

- **One command per submission.** A multi-line
  [irak submission](../../GLOSSARY.md#irak-submission) is one command: only its first
  prompt gets `A` and `B`. The continuation prompts stay bare.
- **When `C` goes out.** irak cannot tell a submission is complete until it has compiled
  it, and running follows compiling without a pause. So `C` is sent from the REPL's
  `ctxsave` hook, which the compiled code calls as it starts running. An incomplete
  submission never runs, so it never gets a `C` too early. A submission that fails to
  compile gets its `C` just before the error is shown.
- **Paging.** irak holds a submission's output to page it, so the marks bypass the
  page and go straight to the terminal. `C` comes before the held output, and a pager
  that runs, with its summary, comes before `D`.
- **The status in `D`.** A failed command's exit status, as `$?` holds it (`D;3` after
  `sh -c 'exit 3'`). Otherwise 1 when the submission threw or returned an unhandled
  `Failure`, else 0. The `!n`, `!!n` and `!p` directives also end with a `D`: 1 when
  the submission or output they name does not exist, or paging is off for `!p`.
- **`exit`.** A submission that calls `exit` gets a `C` but no `D`, since the process
  ends while it runs.
- **When marks are sent.** Only in irak, only with
  [Terminal::LineEditor](../build/AUR.md) as the line editor, and only when standard
  input and output are both a tty. `RAKUDO_DISABLE_OSC133=1` turns them off.

Terminal::LineEditor 0.0.23 lets `A` and `B` go inside the prompt string. Its `prompt`
method prints the string once, as is. Then `read-input` asks the terminal for the cursor
position (`ESC [6n`), and the input field starts at the column the terminal reports.
Escape sequences in the prompt are therefore never counted as width. Edits redraw only
the input field, by moving the cursor relative to where it starts, never the prompt. The
prompt is printed again only after a suspend (Ctrl-Z, then `fg`) and when irak redraws
the line after a terminal resize. Both reprint the prompt at the start of its line, so
sending `A` and `B` again is right.

Readline would need the marks wrapped in `\001`…`\002`, and Linenoise counts every byte
of the prompt as width, so irak sends no marks with them.

The test runs irak under `script(1)` and answers the editor's cursor queries itself. It
drives one prompt per session because of a Terminal::LineEditor 0.0.23 bug that rak's
patches leave in place. After a line
is read, its parser thread stays blocked in `$*IN.read(1)`. MoarVM serializes operations
on a handle, so the next prompt's `$*IN.t` waits for that read. By then the tty is back
in cooked mode, so the read returns only once a whole line is typed. Under a harness
that waits for the prompt before typing, the second prompt stalls. How this shows in a
real terminal has not been checked. The multi-line case is therefore tested up to the
continuation prompt. Repro: `start { $*IN.read(1) }; sleep 1; $*IN.t` blocks until input
arrives.

## Navigating data with TAB and SHIFT-TAB

Status: **not implemented.** This builds on the
[dotty subscripts](dotty-subscripts.md): given `@a.`, `%h.`, or any expression that a dotty
subscript can follow, what should TAB and SHIFT-TAB show? The subscripts define how `.` after a
term *parses*; this section describes what happens at *edit time*, when the cursor sits
after a `.` with nothing typed yet.

### 1. Request

Add two interactive navigation primitives for the `.` subscript surface:

1. **TAB** — after a term followed by `.` (the user has typed `@a.` or
   `%h.` or `$obj.` and pressed TAB before typing any subscript selector),
   show a menu of available keys, indices, or both, depending on the
   subject's representation. The same behavior at `.1` (partially typed
   digit) or `.name` (partially typed identifier) narrows the list by
   prefix matching.

2. **SHIFT-TAB** — after the same `.`-prefixed position, instead of a
   completion menu, dump the structure at that point as YAML (a compact,
   indented preview of what accessing this node would let you reach). If
   the structure is large, truncate at a configurable depth/width.

Both are designed around **REPR** (Raku's representation system), where a
single object can expose both positional and associative access:

```raku
my $m = "hello world" ~~ /(.)\w+ (.)/;  # Match object — REPR is both
# $m[0]   gives 'h'
# $m<0>   gives 'h'  (same, via Str capture-name)
# $m.keys gives ('0',)
```

A nushell user would expect `$m. TAB` to show both numeric indices
(0 through `$m.elems - 1`) and string keys (`$m.keys`), because REPR
exposes both interfaces, and the `.` subscript sugar can reach either one
(depending on what follows `.`). This spec makes that explicit.

### Mnemonic

| Key       | Meaning                                        |
|-----------|------------------------------------------------|
| **TAB**   | "What can I put here?" — list subscripts       |
| **SHIFT-TAB** | "What's under there?" — preview the value  |

Mirrors the nushell convention where TAB completes commands/paths and
SHIFT-TAB previews data structure content inline.

### 2. Grounding: what already exists

#### 2.1 The `.` subscript sugar (this branch, DONE)

After a term, `.` followed by one of four shapes desugars as follows
([dotty subscripts](dotty-subscripts.md)):

| after `.`                | desugars to | target interface |
|---------------------------|-------------|------------------|
| bare integer (`1`)        | `[1]`       | positional       |
| bare identifier (`toto`)  | `<toto>`    | associative      |
| `~expr` (Str‑sigiled)     | `{expr}`  | associative      |
| `#expr` (int‑sigiled)     | `[#expr]`   | positional       |

The interactive mode doesn't need to know which shape the user will pick —
it just needs to know that the *subject* (the term before `.`) exposes one
or both subscript interfaces, and list the available keys/indices for each.

#### 2.2 Raku's `.WHAT`, `.^roles`, `.REPR` introspection

Available at runtime — and in an interactive/REPL context, available in
principle via a `try`-wrapped introspect call on the subject:

```raku
.say for $subject.^attributes;     # list all attributes
$subject.^can('elems') ?? "positional" !! "not positional";
$subject.^can('keys')  ?? "associative" !! "not associative";
```

But for a completion engine, the relevant interface is:

- **Positional (`@`‑ish):** `$subject.elems` gives the count; `^$subject`
  gives the range of valid indices `0..^elems`.
- **Associative (`%`‑ish):** `$subject.keys` lists available keys.

**REPR-aware check:** `$subject.HOW.archetypes.positional` and
`$subject.HOW.archetypes.associative` return `True`/`False` and determine
whether the object can be subscripted with `[...]` or `{...}` respectively
(or both). This is distinct from whether it *happens to have those methods*
— a `Hash` has both archetypes false at the HOW level (it's a concrete
`Hash`, not a parametric role) but its `.keys` method works; the correct
introspection path is `$subject.^can('AT-POS')` / `$subject.^can('AT-KEY')`
for the raw subscript interface, or `.elems`/`.keys` for the human-facing
one. This spec uses the latter (`.elems`/`.keys`) for the completion
display, with the note that `AT-POS`/`AT-KEY` is the definitive check.

**Empty/zero-length subjects** (`my @a;`, `my %h;`): TAB should show
`<empty>` or a dimmed "(no entries)" message, not an empty list or a crash.

#### 2.3 YAML output

No YAML library is assumed in the core. A viable first implementation is a
hand-written recursive subroutine that mirrors `$obj.raku`-style output but
formatted as indented YAML blocks, roughly:

```
- 10
- 20
- 30
```

for a positional array, and:

```
name: Alice
age: 30
```

for an associative structure. For mixed REPR (both positional and
associative), the YAML output should first show the associative keys as
mapping entries, with positional indices collected under an `_indexed:` key
or at a separate YAML document (decided below in §5).

This is deliberately NOT `%h.perl` or `%h.raku` — those produce Raku code,
not structural data. It's also deliberately NOT `.YAML()` from a CPAN
module, to avoid an external dependency in the REPL/bootstrap build.
Instead it produces the simplest YAML subset that a human can scan:

- Scalars: strings, numbers, booleans, `null` (for `Any`/`Nil`).
- Sequences: `- item` style.
- Mappings: `key: value` style.
- Nested structures: indented, 2 spaces per level.
- Depth limit (default 3) with `...` truncation marker.
- Width limit (default 2000 chars per line / 20 items per level) with
  `... and N more` truncation message.

### 3. Proposed behavior

#### 3.1 TAB — list available subscripts

After `@a.` (positional subject):

```
@a.█  →  TAB
─────────────────────────────────────
Indices [0..9] (10 entries):
  0   1   2   3   4   5   6   7   8   9
─────────────────────────────────────
```

If the user has typed a partial digit — `@a.3█` — narrow to `3`‑prefixing
indices:

```
@a.3█  →  TAB
───────────────────────────
Indices matching "3":
  3   30   31   32   …   39
───────────────────────────
```

After `%h.` (associative subject):

```
%h.█  →  TAB
─────────────────────────────────
Keys: name   age   occupation
─────────────────────────────────
```

If the user typed a partial identifier — `%h.n█` — narrow:

```
%h.n█  →  TAB
───────────────────────────
Keys matching "n":
  name
───────────────────────────
```

After `$obj.` where REPR is both positional and associative (e.g. a `Match`
object, an `Any`‑mapped `MixHash`, a custom REPR):

```
$m.█  →  TAB
────────────────────────────────────────────────────
Indices [0..4] (5 entries):   0   1   2   3   4
Keys:   0   1   from   to   orig   str
────────────────────────────────────────────────────
```

Both lists shown, separated by section. A note about the `#`/`~` sigil
choice is *not* shown by default — the completion engine doesn't force the
user to pick a sigil; it shows keys/indices, and the user types the
appropriate selector. If the user tabs on `$m.#█`, only indices are shown.
If the user tabs on `$m.~█` or `$m.█` (identifier regex), only keys are
shown (because `~` and bare identifier both hit the associative path).

**Interaction with `.1` and `.#`:** After `@a.#█`, the TAB menu should show
indices (same as plain `@a.█`). After `%h.~█`, the TAB menu should show
keys (same as plain `%h.█`). This is because `.#` and `.~` are specifying
which *subscript form* the user intends (positional vs associative), not
restricting the *value domain* — the list of available integer indices is
the same whether the user will type `.#3` or `.3`, and the list of keys is
the same whether typed `.~name` or `.name`.

**Interaction with `.name` sugar (`.rak` mode):** In `.rak` mode
([dotty subscripts](dotty-subscripts.md)), a bare identifier after `.` means
`<name>`, i.e. associative. So the TAB menu after `$x.foo█` in `.rak` mode
should show *only* the associative keys (matching prefix `foo`), not
indices. In `.raku` mode, `.foo█` is the start of a method call — TAB
there should show method-name completions (the existing REPL behavior),
not subscript keys. The file extension gate (`$*RAK-SEMANTICS`) is
the natural discriminator: the same dynamic variable that decides how `.`
parses also decides how TAB completion behaves.

**Implementation note — safety:** An arbitrary subject may have side-
effecting `.elems` or `.keys` methods (e.g. an `IO::Cat` that opens files, a
lazy `Seq` that must be consumed to report an element count). The
completion engine MUST:
- **Time-box** the introspection (wall‑clock timeout, e.g. 500ms total).
- **Catch exceptions** from `.elems` / `.keys` and fall back to
  `<side-effecting — can't enumerate>` or the count from `.WHICH` alone.
- **Not consume** lazy structures — for a `Seq`, check `$seq.is-lazy`
  first; if True, show `<lazy — count unknown>`.
- **Cache** the result for the same textual subject expression within a
  single completion session (the user might TAB twice with no intervening
  keystroke).

#### 3.2 SHIFT-TAB — preview structure as YAML

After `@a.█` SHIFT-TAB:

```yaml
- "first"
- "second"
- "third"
```

After `%h.█` SHIFT-TAB:

```yaml
name: Alice
age: 30
occupation: engineer
```

After `$match.█` SHIFT-TAB (mixed REPR):

```yaml
# Positional indices [0..4]:
- "h"
- "ello"
- "w"
- "orld"
# Associative keys:
from: 0
orig: "hello world"
str: "h"
to: 2
```

The YAML preview should:
1. Show the **top-level** subscript targets (all indices or keys reachable
   by a single `.selector` from the subject).
2. Optionally (default on) drill one level deeper for a sample of items —
   e.g. for a hash of hashes, the first 3 keys' values are also expanded.
   Depth is configurable but defaults to 1 (top level only) for SHIFT-TAB
   and 2 for a double-tap SHIFT-TAB (hold and press again).
3. For large structures: truncate at 50 entries per level, with
   `... and 172 more` appended.
4. For lazy/uncountable subjects: `<lazy — preview not available>` or
   `<lazy — first N items only>` where N is configurable (default 10).
5. For side-effecting subjects: same time-box and catch-all as TAB.

#### 3.3 YAML renderer specification

The YAML output must be valid YAML 1.2 for the subset it covers. The
renderer is a standalone function `yaml-preview($subject, :$max-depth = 1,
:$max-items = 50, :$max-width = 2000)` that produces a `Str`. Rules:

- Scalars: `.raku` style for strings (quoted if they contain special chars
  or YAML‑ambiguous prefixes like `true`/`false`/`null`/digits with
  leading zero), numeric `.raku` for numbers, plain `true`/`false`/`null`
  for `Bool`/`Nil`/`Any`.
- Sequences: `- value` with each value on its own line, indented 2 spaces
  per nesting level.
- Mappings: `key: value` with each pair on its own line, indented 2 spaces
  per level.
- Nested sequences/mappings within a value are indented further and
  rendered recursively — e.g. a hash with an array value:

  ```yaml
  tags:
    - perl
    - raku
    - language
  ```

- Mixed REPR (both positional and associative): rendered as a mapping with
  a synthesized key `_indices` for the positional part, plus the associative
  keys as normal mapping entries. This is a design choice (not standard
  YAML) to avoid YAML's inability to have both `-` sequence items and
  `key:` mapping items at the same level. Alternative: output two YAML
  documents separated by `---` — first document is the positional sequence,
  second document is the associative mapping — and let the reader/viewer
  handle them. **Decision:** single mapping with `_indices`, because
  SHIFT-TAB is a quick preview, not a data-exchange format. Two-document
  output would split what the user sees across two scroll regions, which is
  harder to scan at a glance. The `_indices` key is always emitted with a
  YAML‑comment annotation (`# positional`) for clarity:

  ```yaml
  _indices:   # positional
    - "h"
    - "ello"
    - "w"
    - "orld"
  from: 0
  orig: "hello world"
  str: "h"
  to: 2
  ```

### 4. Implementation sketch

#### 4.1 Where this lives: the REPL, not the grammar

Unlike the dotty subscripts, which modify `src/Raku/Grammar.nqp`
and `src/Raku/Actions.nqp`, this feature lives **outside the compiler core**,
in whichever frontend provides interactive editing:

- If the Raku REPL (`src/core.c/REPL.rakumod`, `src/Perl6/REPL.nqp`) is
  enhanced: the TAB/SHIFT-TAB handler intercepts the cursor position,
  walks backward to find the `.` and its subject expression, eval‑introspects
  the subject, and produces the completion/preview display.
- If a Language Server Protocol (LSP) implementation is the target:
  `textDocument/completion` and `textDocument/hover` (or a custom
  `textDocument/preview`) handlers implement the same logic. This spec
  assumes the REPL is the first target (lowest friction, fastest iteration)
  and leaves LSP to a follow-up.

#### 4.2 REPL‑level pseudocode

```
on tab(editor-buffer, cursor-pos):
    prefix = buffer[0..cursor-pos]   # everything left of cursor
    if prefix matches / (.+) \. $ /:
        subject-expr = $1             # the term before the last dot
        selector-prefix = ""          # nothing typed after the dot yet
    elsif prefix matches / (.+) \. (\w*)$ /:
        subject-expr = $1
        selector-prefix = $2          # partial identifier/digit
    else:
        fallback to normal TAB completion (current REPL behavior)

    subject = try-eval(subject-expr)
    unless subject.defined:
        show "<unknown subject>"
        return

    # Determine available interfaces
    my @indices   = subject.^can('AT-POS') ?? 0 ..^ subject.elems !! ()
    my @keys      = subject.^can('AT-KEY')  ?? subject.keys     !! ()

    # Filter by selector-prefix (if any)
    @indices = @indices.grep: *.Str.starts-with(selector-prefix)
    @keys    = @keys.grep:    *.starts-with(selector-prefix)

    # Display
    if @indices:
        display-section("Indices [{@indices.min}..{@indices.max}] ({@indices.elems} entries)",
                        @indices.join("    "))
    if @keys:
        display-section("Keys", @keys.join("   "))
    if !@indices && !@keys:
        display-section("(no subscriptable entries)", "")
```

```
on shift-tab(editor-buffer, cursor-pos):
    prefix = (same detection logic as tab)
    subject = try-eval(subject-expr)

    yaml = yaml-preview(subject, max-depth => 1, max-items => 50)
    show-preview-window(yaml)
```

The `yaml-preview` function:

```
sub yaml-preview($subject, :$max-depth = 1, :$max-items = 50, :$max-width = 2000, :$depth = 0) returns Str:
    return "<max-depth>" if $depth >= $max-depth
    return "<max-width truncated>" if accumulated-width >= $max-width

    my $indent = "  " x $depth

    if $subject.^can('AT-KEY') && $subject.^can('AT-POS'):
        # Mixed REPR — use _indices convention
        return render-mixed-repr($subject, :$max-depth, :$max-items, :$max-width, :$depth)

    if $subject.^can('AT-KEY'):
        # Associative — mapping
        my @keys = $subject.keys
        @keys = @keys[0..^min(@keys.elems, $max-items)]
        my $truncated = @keys.elems < $subject.keys.elems
        my @lines
        for @keys -> $k:
            @lines.push: "$indent$k: {yaml-preview($subject{$k}, :$max-depth, :$max-items, :$max-width, depth => $depth + 1)}"
        if $truncated:
            @lines.push: "$indent... and {$subject.keys.elems - $max-items} more"
        return @lines.join("\n")

    if $subject.^can('AT-POS'):
        # Positional — sequence
        my $elems = $subject.elems
        my $count = min($elems, $max-items)
        my @lines
        for ^$count -> $i:
            @lines.push: "$indent- {yaml-preview($subject[$i], :$max-depth, :$max-items, :$max-width, depth => $depth + 1)}"
        if $count < $elems:
            @lines.push: "$indent- ... and {$elems - $count} more"
        return @lines.join("\n")

    # Scalar fallback
    return scalar-yaml($subject)
```

#### 4.3 Safety: lazy, side-effecting, and infinite subjects

Every `.elems` and `.keys` call in the TAB/SHIFT-TAB path must be wrapped:

```raku
sub safe-elems($subject) {
    return "<lazy>" if $subject.^can('is-lazy') && $subject.is-lazy;
    try {
        my $timeout = Promise.in(0.5);
        my $result  = Promise.start({ $subject.elems });
        await any($result, $timeout);
        $result.status ~~ Kept ?? $result.result !! "<timeout>";
    }
}
```

Same pattern for `.keys`. The REPL itself runs in a single-threaded event
loop, so blocking for 500ms is acceptable (the user already waited for a
TAB press); an LSP implementation would use a non‑blocking request.

#### 4.4 Caching

Within one interaction (TAB, modify, TAB, modify, SHIFT-TAB), the
introspection result for the *same textual subject expression* is cached.
Key = `$subject-expr` as a string; value = `{ indices => ..., keys => ...,
yaml => ... }`. The cache is cleared when the cursor leaves the `.`
position (i.e., the user moves the cursor to a different line, or types
a space, or deletes back past the subject).

### 5. Open questions and design decisions

#### 5.1 Where should `_indices` appear in mixed‑REPR YAML?

Two alternatives considered:

| Option       | Rendering                                    | Trade‑off                              |
|--------------|----------------------------------------------|-----------------------------------------|
| **Single mapping with `_indices` key** | `_indices: [a, b, c]` plus `{key: val}` entries | One document, easy to scan. Synthetic key name. |
| **Two YAML documents** (`---` separator) | `---\n- a\n- b\n---\nkey: val` | No synthetic keys. Harder to read on one screen. Viewer may not handle multi‑doc YAML. |

**Decision: single mapping with `_indices`.** Rationale: SHIFT-TAB is a
preview, not an interchange format. A single scrolling region is more
important than purity of the YAML spec. The `_indices` key is decorated
with a YAML comment (`# positional`) to disambiguate.

#### 5.2 Should SHIFT-TAB also work on a *complete* subscript expression?

After the user types `@a.3` and SHIFT-TABs before hitting Enter, should the
preview show the value at `@a[3]` (a single scalar) or the top-level
structure of `@a`? **Decision: the latter.** SHIFT-TAB always previews the
*subject* of the current `.`, not the subscript result. The `.` is the
"navigation anchor" — TAB/SHIFT-TAB answer "where am I / what can I step
into," not "what does the complete line evaluate to." The latter is what
`say` / the REPL's auto‑print does on execution. So `@a.3█` SHIFT-TAB still
previews `@a`'s indices and keys, not the single value at index 3.

If the user wants to preview a specific subscript result, they should
complete the expression and press Enter (execution), or type `.` again to
drill into that result: `@a.3.█` TAB would then show what's inside
`@a.3`'s value.

#### 5.3 Should TAB also offer `->` completions in `.rak` mode?

In `.rak` mode, `.name` is a subscript and `->name` is a method call.
After `%h.█` TAB in `.rak` mode, should the menu *also* show available
`->method`s? **Decision: no.** The TAB is anchored on `.`, so it answers
"what subscripts can I type after this `.`?" `->name` completions would
be a separate interaction (triggered by typing `->` and then TAB). Splitting
the menu prevents confusion between subscript keys and method names at the
same position.

#### 5.4 Does TAB need to show `~`/`#` sigil hints?

After `@a.█` TAB, should the menu say "use `#3` (not `3`) for native‑int
subscript"? **Decision: no, not in the initial version.** The TAB output
shows plain integers. The user already has a choice between `.3` (bare
digit → sugar for `[3]`) and `.#n` (sigil → `[#n]`). The completion menu
doesn't need to explain this; the user can type either form. A future
version may add a tooltip or a `#` suffix hint, but it's explicitly out of
scope for MVP.

#### 5.5 LSP integration surface

For a Language Server Protocol implementation, the mapping is:

| Editor action | LSP request                          |
|---------------|--------------------------------------|
| TAB           | `textDocument/completion`            |
| SHIFT-TAB     | `textDocument/hover` (with YAML content) or a custom command `textDocument/preview` |

The completion response would include a custom `CompletionItemKind` hint
so the editor can render indices and keys differently. The hover response
would return a `MarkupContent` with `kind: 'markdown'` and the YAML inside
a fenced code block (` ```yaml `).

### 6. Explicitly out of scope for MVP

- Any grammar‑level change to support this — it's entirely a REPL/LSP‑level
  feature, not a new parse rule.
- `.keys` / `.elems` results for subjects that require `use`‑loading a
  module the REPL hasn't seen yet (the subject must be evaluable in the
  current scope; unknown symbols get `<unknown subject>`).
- Fuzzy or substring matching in TAB (only prefix matching, mirroring how
  most shells complete).
- Preview of `->` method calls (only `.`‑subscript preview).
- Folding the YAML preview into a column/buffer view (terminal REPL
  displays it inline; LSP shows it in a hover/completion-detail popup).
- Editing the YAML and writing back to the structure (read‑only preview).
- `$*RAK-SEMANTICS` awareness for environments that don't have it
  (if the compiler doesn't export this variable, fall back to traditional
  REPL completion — no `.`‑subscript‑specific behavior).

### 7. Acceptance criteria (test plan)

A test file `t/02-rakudo/interactive-navigation.t` (REPL‑simulation via
`Proc::Async` driving a REPL subprocess) should assert:

**TAB — positional:**
- `my @a = <a b c>; [streaming input] @a.` TAB → menu contains `0`, `1`, `2`
- `my @a = <a b c>; @a.1` TAB → matches `1` (narrowed), does NOT show `0` or `2`
- `my @a;` (empty array) TAB → shows `<empty>` indicator

**TAB — associative:**
- `my %h = a => 1, b => 2; %h.` TAB → menu contains `a`, `b`
- `my %h = a => 1, b => 2; %h.a` TAB → matches `a`, does NOT show `b`
- `my %h;` (empty hash) TAB → shows `<empty>` indicator

**TAB — mixed REPR (e.g. Match):**
- `my $m = "abc" ~~ /(.)(.)/; $m.` TAB → menu includes indices `0` `1` AND
  associative keys (at minimum `0`, `1`, `from`, `to`, `orig`, `str`)

**TAB — safety:**
- `my $lazy = (1..Inf).grep(* %% 2); $lazy.` TAB → shows `<lazy — count unknown>`
  or similar, does not hang
- A subject whose `.keys` croaks → shows `<error>` indicator, does not abort

**SHIFT-TAB — YAML:**
- `my @a = <x y z>; [cursor at @a.]` SHIFT‑TAB → output matches
  ```
  - "x"
  - "y"
  - "z"
  ```
- `my %h = name => "Alice", age => 30; %h.` SHIFT‑TAB → output matches
  ```
  name: "Alice"
  age: 30
  ```
- Mixed REPR preview uses `_indices:` convention
- Depth truncation (max‑depth=1 on a hash of hashes shows `<max-depth>` for
  nested values, not full expansion)
- Large array (100 elements, max‑items=10) shows `... and 90 more`

**Extension‑aware behavior:**
- In `.raku` mode (at a REPL that tracks the file type): `.foo` TAB → method
  completions, not subscript keys
- In `.rak` mode: `.foo` TAB → subscript keys (as above)

(Note: testing the file‑extension gate from the REPL is non‑trivial — `EVAL`
has no notion of a source‑file extension. The test may need to either
launch a subprocess with a `.rak`/`.raku` temp file that exercises a REPL‑
simulation `$*IN` feed, or accept that extension‑aware tests are done at
the `dot-subscript-name.t` level only and mark this test as `todo`.)

### 8. Prior art: nushell's navigation model

Nushell's `ls` / `open` / `$env` / `$config` navigation works as follows

| Action     | Result                                                    |
|------------|-----------------------------------------------------------|
| `ls ` TAB  | Shows files/dirs in current dir (completion list)         |
| `open .` TAB  | Lists fields within a structured file                    |
| `ls | where` TAB | Shows column names                                 |
| SHIFT-TAB  | Preview pane shows file contents or data sample           |

This spec mirrors that: `.` is analogous to `ls`'s path separator (it opens
a "directory" of subscriptable entries), TAB lists the entries, and
SHIFT-TAB previews the content at that point without committing to a
selection.

The key difference: nushell's TAB is purely filesystem‑ or column‑oriented;
Raku's `.` is polymorphic (positional, associative, mixed REPR), so the
completion engine must detect the interface at runtime rather than assuming
a fixed schema. The `_indices` convention for mixed REPR in SHIFT-TAB is
analogous to nushell's handling of records that are both `list` and
`record` (e.g. `open` on a JSON file that is an array of objects — nushell
shows both the array index and the object keys).

### 9. Future directions (post‑MVP)

- **Visual preview**: Instead of text YAML, a tree‑widget in the terminal
  (e.g., `blessed`‑style or `Ratatouille`‑rendered) that lets the user
  expand/collapse nodes with arrow keys, then insert the selected path as
  a `.`‑subscript expression. This is a full‑terminal‑UI feature, far
  beyond the MVP SHIFT-TAB YAML dump.

- **Write‑back**: After preview, allow the user to edit a value in the YAML
  and commit it back to the structure (e.g., change a hash value or an
  array element). This would require tracking the navigation path as a
  sequence of subscript operations and applying the edited value through
  them. Not part of MVP.

### 10. Borrowing nushell's interactive API for `rak`

Nushell is installed at `/usr/bin/nu` and cloned to `~/git/nushell---nushell`
(commit 798c55d on this system). Its interactive layer is a Rust stack:
`reedline` (line editor), `nu-cli` (completions/menus/keybindings), and
`nu-explore` (TUI data previewer). This section evaluates whether to embed,
wrap, or ignore that stack for `rak`.

#### 10.1 What nushell's source offers

| Crate | Path in source tree | Relevance |
|---|---|---|
| `reedline` | External dependency (not vendor in this clone) | Tab/BackTab handling, completion menus, multi-line editing, history, keybinding configuration |
| `nu-cli` | `crates/nu-cli/` | Completion framework with `CellPathCompletion` (its `.cell_path` completer already does what this spec describes: after `$obj.`, it eval-walks the object and lists `.keys`/`.elems` as completions) |
| `nu-explore` | `crates/nu-explore/` | TUI table/record pager with keyboard navigation, expand/collapse nested values, `--peek` to extract a cell value on exit |

**`CellPathCompletion`** (`crates/nu-cli/src/completions/cell_path_completions.rs`)
is the closest analogue to this spec's §3.1. It:
1. Walks the `FullCellPath` AST to find which `.member` the cursor is on.
2. Evaluates the tail of the path up to that point (`eval_cell_path`).
3. Calls `get_columns` on the result (which returns `.keys()` for records,
   `.column_types()` for tables).
4. Filters by prefix and returns completions as reedline `Suggestion` objects.

This is almost exactly what §4.2 sketches in pseudocode — except nushell
eas only records/tables (nu's type system), while we need generic
`AT-POS`/`AT-KEY`-detection for any Raku object.

**`nu-explore`** is a full-screen TUI pager (~500 lines across
`crates/nu-explore/src/explore/` plus supporting code). It renders any
nushell `Value` as an interactive tree with:
- Arrow keys to move between rows
- Enter to drill into a nested value
- `q`/`Esc` to close
- `--peek` to print the cursor cell value on exit (`explore -p`)

It uses `crossterm` for raw terminal control, which is the same TUI library
`Terminal::LineEditor` (already a Raku REPL backend) wraps.

#### 10.2 The architectural mismatch

Despite the functional overlap, embedding nushell's Rust TUI directly into
`rak` is impractical:

1. **Language boundary.** Nushell is at least 10 Rust crates totalling
   >61MB, all compiled to a standalone ELF with no public C ABI. The Raku
   REPL runs on MoarVM (NQP/Raku). Calling into nushell's internals would
   require either a C FFI bridge (which nushell does not expose) or a
   subprocess protocol (too slow for per-keystroke TAB).

2. **reedline is already superseded.** The Raku REPL already abstracts
   over three line-editor backends: `Readline`, `Linenoise`, and
   `Terminal::LineEditor` — the last of which is a pure-Raku module that
   provides the same keybinding/completion/history primitives as reedline.
   Adding a fourth backend that talks to reedline over IPC would be
   redundant.

3. **`CellPathCompletion` is nushell-specific.** Its `eval_cell_path` works
   on nushell's own AST and type system, not on arbitrary Raku objects.
   We need to call `AT-POS`/`AT-KEY` on a Raku value — a fundamentally
   different evaluation path. The *idea* („walk the path, eval the subject,
   list its columns“) is what we borrow; the code is not reusable.

4. **`nu-explore` is a full TUI, not a library.** It captures the terminal
   and runs its own event loop. You can't call it on a single value mid-REPL
   without forking a subprocess, waiting for the user to quit, and parsing
   the `--peek` output — an awkward dance with ~60ms startup cost per
   invocation. A lighter-weight approach for SHIFT-TAB is a few lines of
   Raku code that renders the YAML preview inline (§3.2) or, in a future
   version, a minimalist tree widget using the same `Terminal::LineEditor`
   backend the REPL already uses.

#### 10.3 What we borrow: design, not code

| Idea | Nushell's implementation | Our analogue |
|---|---|---|
| Cell-path completions after `.` | `CellPathCompletion` in `nu-cli` | §4.2's `subscript-completions` in `Completions` role |
| BackTab as distinct from Tab | `completion_previous` bound to `BackTab` in reedline config | §5.3, §10.6 (BackTab → YAML preview, handled in `Terminal::LineEditor` backend) |
| Explore value by key | `nu-explore` with `--peek` | §3.2's inline YAML (MVP), future tree-widget (§9) |
| Columns from runtime value | `get_columns()` (calls `.keys` on record) | `safe-keys($subject)` via `AT-KEY` detection |
| External completer protocol | `$env.config.completions.external`: shell out to any binary returning JSON | §12 (future: `rak --complete` as nushell external completer for `.rak` files) |

#### 10.4 The REPL already has the right hook

The Raku REPL's `Completions` role (`src/core.c/REPL.rakumod`, lines
~167-215) has a `completions-for-line` method that all three backends call.
It currently returns identifier completions (CORE:: symbols, lexical scope
variables). The gap is that it has no awareness of `.` as a subscript anchor.

This spec adds one new method and extends `completions-for-line`:

```raku
# New helper: detect whether cursor is in a `.`-subscript position
method parse-at-cursor(Str $line, int $cursor-index --> SubscriptAnchor) { ... }

# New helper: eval the subject, list its keys/indices, filter by prefix
method subscript-completions(Str $subject-expr, Str $prefix --> Seq) { ... }

# Extended existing method:
method completions-for-line(Str $line, int $cursor-index) {
    my $parsed = self.parse-at-cursor($line, $cursor-index);
    return self.subscript-completions($parsed.subject, $parsed.prefix)
        if $parsed.is-subscript-anchor;
    # ... existing logic unchanged (CORE:: + lexical scope) ...
}
```

No Rust code, no subprocess, no new binary. The `Terminal::LineEditor`
backend already distinguishes Tab from BackTab at the raw-terminal level
(SHIFT-TAB → `KeyCode::BackTab` in reedline's terminology as well —
confirmed in `reedline_config.rs` line 18: `"backtab" => KeyCode::BackTab`),
so adding a SHIFT-TAB → YAML-preview path there is ~50 lines of Raku.

The `Linenoise` backend does not expose BackTab natively — SHIFT-TAB there
falls back to no-op for MVP. `Readline` may handle it if configured via
`.inputrc`; that's best-effort.

#### 10.5 Decision summary

| Option | Viable? | What it costs | Recommendation |
|---|---|---|---|
| Embed reedline via Rust FFI in `rak` | No | Requires C ABI from reedline, MoarVM NativeCall bridge, new build dep | **Reject** — the REPL already has a pure-Raku line editor backend |
| Call `nu --explore` as subprocess for SHIFT-TAB | Technically yes | ~60ms startup per invocation, awkward stdin/stdout juggle | **Acceptable as a configurable option**, not the default |
| Write a nushell external completer (`rak --complete`) | Yes | ~50 lines of Raku + one line of nushell config | **Future (§12)** — orthogonal to the REPL, useful for people who edit `.rak` files in nushell |
| **Extend the existing Raku REPL's `completions-for-line`** | **Yes** | Pure Raku, no new deps, ~200 lines total | **Default path for MVP** |
| BackTab → YAML preview via `Terminal::LineEditor` | **Yes** | ~50 lines of Raku (new method on REPL) | **Default path for MVP** |

#### 10.6 Nushell external completer (future, §12 sketch)

If nushell is configured as the user's shell, `rak --complete` could serve
as nushell's external completer for Raku source files:

```nushell
# In $env.config.completions.external:
completer: {|ctx|
    if ($ctx.file | path extension) =~ 'rak|raku|rakumod|pm6' {
        ^rak --complete $ctx.line $ctx.pos
        | from json
    }
}
```

Where `rak --complete` reads `$line` and `$pos` from argv, parses the
buffer to find `.`-subscript positions, and returns completions as JSON:

```json
[
  {"value": "name", "description": "Str key"},
  {"value": "age", "description": "Int key"}
]
```

This is a small, standalone Raku script registered as a nushell plugin.
It does not require the full REPL; it only needs the `Completions`-role
logic (parse-at-cursor + subscript-completions) factored into a library
that both the REPL and the `--complete` entry point can use.

#### 10.7 Integration architecture (final)

```
╔═══════════════════════════════════════════════════════════════════╗
║                    Raku REPL (src/core.c/REPL.rakumod)          ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │ Completions role                                         │    ║
║  │  - completions-for-line (existing: symbols)              │    ║
║  │  + parse-at-cursor        (NEW: detect . as anchor)      │    ║
║  │  + subscript-completions  (NEW: eval subject, list keys) │    ║
║  │  + yaml-preview           (NEW: BackTab → YAML preview)  │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║  ┌────────────┬──────────────┬────────────────────┐            ║
║  │ Readline   │ Linenoise    │ Terminal::LineEditor│            ║
║  │ (Tab only) │ (Tab only)   │ (Tab + BackTab)     │            ║
║  └────────────┴──────────────┴────────────────────┘            ║
╚═══════════════════════════════════════════════════════════════════╝
                           │
                           v
╔═══════════════════════════════════════════════════════════════════╗
║              `rak` binary (shell wrapper, sets RAKU_RAK_MODE=1)   ║
║  Gives $*RAK-SEMANTICS=1 in irak (no source file)          ║
║  Also provides `rak --complete` for nushell external completer   ║
╚═══════════════════════════════════════════════════════════════════╝
                           │
                           v
╔═══════════════════════════════════════════════════════════════════╗
║  Nushell integration (optional, post-MVP)                       ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │ External completer: `rak --complete $line $pos`         │    ║
║  │ Returns JSON completions to nushell's reedline          │    ║
║  │ Registered in $env.config.completions.external          │    ║
║  └─────────────────────────────────────────────────────────┘    ║
╚═══════════════════════════════════════════════════════════════════╝
```