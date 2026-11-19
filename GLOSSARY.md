# rak

The `.rak` frontend of this Rakudo fork: Raku plus a shellish surface syntax. A source
compiled in rak mode gets the extra spellings below; the same text compiled as ordinary
Raku must not.

## Language

<a id="rak-mode"></a>**rak mode**:
The language mode a `.rak` source is compiled in, in which naked strings, the dotty
subscript, the new sigils and redirection are available. A source with any other
extension compiles as ordinary Raku, and the feature set must not leak into it.
_Avoid_: rak semantics, shell mode, extended Raku.

<a id="standard-strategy"></a>**standard strategy**:
The default way a statement parses in rak mode: Raku syntax, plus naked strings, the
dotty subscript, the new sigils and redirection. Where rak mode is chosen per source
file, a strategy is chosen per statement or parenthesized group.
_Avoid_: standard mode, normal mode, Raku mode.

<a id="shell-strategy"></a>**shell strategy**:
The way a statement or parenthesized group parses when it reads as a command line: the
first word names what to run (an alias, a routine, a builtin or an external command)
and the words after it are its arguments. It takes the slot that Raku reports as the
error "two terms in a row", so no valid Raku program changes meaning. Planned, not
implemented.
_Avoid_: shell mode, command mode.

<a id="irak"></a>**irak**:
An interactive rak session: the execution context in which rak evaluates statements with
no source file (REPL, `-e`, standard input). An execution context, not a mode: its
statements still parse in the standard or shell strategy. Pronounced "eye-rak".
_Avoid_: interactive mode, irak mode, REPL mode.

<a id="irak-submission"></a>**irak submission**:
The text entered at the irak prompt and evaluated as a unit: one line, or several when
the first is incomplete and irak asks for more with its continuation prompt. The `[N]`
in the prompt counts submissions.
_Avoid_: line, statement, command, cell.

<a id="irak-topic"></a>**irak topic**:
At the start of an irak submission, `$_` holds the value of the previous submission, so a
leading dotty subscript reaches into it. A submission that fails, returns `Nil`, or
prints output instead of a value leaves `$_` unchanged.

<a id="naked-string"></a>**naked string**:
An unquoted word that denotes a string literal: it starts with a letter or underscore and
contains no whitespace. A word is not a naked string when it is a keyword (`if`, `given`,
`return` keep their meaning and are never a string), when it names an already-known routine
or variable, or when `(` follows it. "Already-known" is decided as the parser walks the
file, so position matters: `say foo; sub foo { 42 }` prints `foo`, while
`sub foo { 42 }; say foo` prints `42`.
_Avoid_: bareword, unquoted literal, identifier.

<a id="new-sigils"></a>**new sigils**:
The `~` and `#` sigils, denoting a native string and a native integer respectively, in
addition to Raku's existing sigils.

<a id="dotty-subscript"></a>**dotty subscript**:
A leading `.` spelling a subscript without brackets: `.name` is the hash subscript
`<name>`, `.'key'` / `."key"` are the hash subscripts `{'key'}` / `{"key"}` (the
double-quoted one interpolates), and `.1` / `.~expr` / `.#expr` subscript by an
expression. The `->name`
spelling instead calls a parameterless method, and `->$var` / `->&f` make Raku's
indirect method call (`.$var` / `.&f` are errors in rak mode). With nothing before it, a leading `.`
subscripts the topic `$_` (`.name` is `$_<name>`), and a leading `->name` calls the method
on `$_`.
_Avoid_: dot syntax, method sugar.

<a id="redirection"></a>**redirection**:
A shellish operator attached to a single statement that sends that statement's output to
a file or takes its input from one. The operator is written touching its target, so an
operator with whitespace after it stays an ordinary Raku operator.
_Avoid_: pipe, stream redirect.

<a id="output-redirection"></a>**output redirection**:
The suffix form: `STMT >target` writes to the file, truncating it; `STMT >>target`
appends to it.

<a id="input-redirection"></a>**input redirection**:
The prefix form `STMT` written as `<target STMT`.

<a id="redirection-target"></a>**redirection target**:
The file the operator is attached to. It is a naked string, a quoted string, or a
variable.
_Avoid_: filename argument, path expression, output file.

<a id="load"></a>**load**:
The suffix form `LVALUE <target`: the target's content, decoded by its format, is assigned
to the left-hand side, which can be anything assignable (`my %cfg <cfg.json`). A bare
`<target` with nothing on the left loads into the topic `$_`. Unlike input redirection,
the standard input stream is not involved.
_Avoid_: slurp-assign, suffix input redirection.

<a id="format"></a>**format**:
How a redirection target's content is decoded and encoded, chosen from the target's
extension, ignoring case (`.json`, `.jsonl`). A target whose extension has no format is
plain text.
_Avoid_: codec, file type, serializer.

<a id="text-mode"></a>**text mode**:
How output redirection behaves when the statement prints: the printed text is what goes to
the target. If the target has a format, that text must decode in it, and is re-encoded in
standard form.

<a id="value-mode"></a>**value mode**:
How output redirection behaves when the statement prints nothing and the target has a
format: the statement's value is encoded and written.

<a id="pipeline"></a>**pipeline**:
A sequence of pipeline stages joined by pipes, in which the output of each stage is the
input of the next. Planned, not implemented.

<a id="pipeline-stage"></a>**pipeline stage**:
One element of a pipeline: either an external command, which reads and writes bytes, or
a rak routine, method or block, which reads and writes values without starting a
process. A stage that emits several values produces a lazy `Seq`, or a `Supply` when the
stream is asynchronous.
_Avoid_: filter, step, command (for a rak stage).

<a id="pipe"></a>**pipe**:
The operator joining two pipeline stages, spelled `|` in the shell strategy. In the
standard strategy, `|` keeps its Raku meanings (the `any` junction infix, the slip
prefix), so the strategy, not spacing, decides what `|` is. Values pass between
rak stages unchanged; where an external command meets a rak stage, bytes become lines
(or decoded values when a format is given) and values become text (or are encoded in a
format). Unlike redirection, a pipe connects stages rather than attaching a statement
to a redirection target.
_Avoid_: redirection, feed.

<a id="huff"></a>**huff**:
To give a construct a spelling whose length fits how often it is used, after Huffman
coding: frequent constructs get short spellings. rak huffs Raku constructs that are
frequent in conversation at the command line (`say foo` for `say 'foo'`, `%h.name` for
`%h<name>`).
_Avoid_: huffmanize, abbreviate, sugar.

<a id="unhuff"></a>**unhuff**:
To give a rare construct a longer spelling, freeing its short one for a more frequent
construct. In rak mode, `.5` means `$_[5]`, so the number is written `0.5`.
