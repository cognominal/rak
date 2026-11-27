# rak

The `.rak` frontend of this Rakudo fork: Raku plus a shellish surface syntax. A source
compiled in rak mode gets the extra spellings below; the same text compiled as ordinary
Raku must not.

## Contents

[alias](#alias) ·
[bare host](#bare-host) ·
[builtin](#builtin) ·
[capability](#capability) ·
[cell](#cell) ·
[command](#command) ·
[command catalog](#command-catalog) ·
[dotty subscript](#dotty-subscript) ·
[dwim](#dwim) ·
[exit status](#exit-status) ·
[external command](#external-command) ·
[filesize](#filesize) ·
[format](#format) ·
[formatter](#formatter) ·
[huff](#huff) ·
[input redirection](#input-redirection) ·
[irak](#irak) ·
[irak prompt](#irak-prompt) ·
[irak submission](#irak-submission) ·
[irak topic](#irak-topic) ·
[load](#load) ·
[naked string](#naked-string) ·
[new sigils](#new-sigils) ·
[output redirection](#output-redirection) ·
[paging](#paging) ·
[pinned topic](#pinned-topic) ·
[pipe](#pipe) ·
[pipeline](#pipeline) ·
[pipeline stage](#pipeline-stage) ·
[plain syntax](#plain-syntax) ·
[rak mode](#rak-mode) ·
[redirection](#redirection) ·
[redirection target](#redirection-target) ·
[selector](#selector) ·
[shell syntax](#shell-syntax) ·
[startup file](#startup-file) ·
[table](#table) ·
[tag](#tag) ·
[text mode](#text-mode) ·
[topic](#topic) ·
[topic-keeping submission](#topic-keeping-submission) ·
[topic-setting submission](#topic-setting-submission) ·
[topical command](#topical-command) ·
[unhuff](#unhuff) ·
[unit literal](#unit-literal) ·
[URL target](#url-target) ·
[value mode](#value-mode) ·
[verb](#verb)

## Language

<a id="rak-mode"></a>**rak mode**:
The language mode a `.rak` source is compiled in, in which naked strings, the dotty
subscript, the new sigils and redirection are available. A source with any other
extension compiles as ordinary Raku, and the feature set must not leak into it.
_Avoid_: rak semantics, shell mode, extended Raku.

<a id="plain-syntax"></a>**plain syntax**:
The default way a statement parses in rak mode: Raku syntax plus naked strings, the
dotty subscript, the new sigils and redirection. Where rak mode is chosen per source
file, plain or shell syntax is chosen per statement or parenthesized group.
_Avoid_: standard strategy, standard mode, normal mode, Raku syntax.

<a id="shell-syntax"></a>**shell syntax**:
The way a statement or parenthesized group parses when it reads as a command line: the
first word names what to run (an alias, a routine, a builtin or an external command)
and the words after it are its arguments. It takes the slot that Raku reports as the
error "two terms in a row", so no valid Raku program changes meaning.
_Avoid_: shell strategy, shell mode, command mode.

<a id="command"></a>**command**:
What the first word of a shell-syntax statement names: a rak routine, a builtin or an
external command. A word on its own at statement level that names an external
command is a command, not a naked string. A rak name wins over an external command of
the same name.
_Avoid_: program (for a rak routine), stage (outside a pipeline).

<a id="external-command"></a>**external command**:
A program found on `$PATH` and run as a child process. Written `^name`, it is the
external command even when a rak name hides it. At statement level its output goes
straight to the terminal; when its value is used, its output is captured.
_Avoid_: binary, executable.

<a id="builtin"></a>**builtin**:
A command that ships with rak and is the same for every user, such as `cd` or `type`.
Whether it is written in Raku or in rak does not matter; what a user defines is never a
builtin.
_Avoid_: shell builtin, user builtin, rak builtin (for a user's own definition).

<a id="alias"></a>**alias**:
A name that stands for a command and its leading arguments, declared with
`alias name=…` and seen only in command position. It is looked up before rak routines,
builtins and `$PATH`.
_Avoid_: abbreviation, shortcut, macro.

<a id="startup-file"></a>**startup file**:
The user's own rak source that the [irak prompt](#irak-prompt) runs before the first
submission: their aliases, routines and settings. It lives in the user's rak config
directory, which follows the XDG conventions on every platform.
_Avoid_: rc file, profile, user builtins, dotfile.

<a id="exit-status"></a>**exit status**:
How an external command ended: its exit code, or the signal that killed it. `$?` holds
the last one in the current routine; a rak routine run as a command leaves it
unchanged. For a pipeline, `$?` is the first command that failed, else the last, and
`@?` holds every command's. A non-zero exit status fails a `.rak` file; irak only shows it.
_Avoid_: return code, error code.

<a id="irak"></a>**irak**:
An interactive rak session: the execution context in which rak evaluates statements with
no source file (REPL, `-e`, standard input). An execution context, not a mode: its
statements still parse in plain or shell syntax. Pronounced "eye-rak".
_Avoid_: interactive mode, irak mode, REPL mode.

<a id="irak-prompt"></a>**irak prompt**:
irak reading its submissions from a person at a terminal, as opposed to `-e` or piped
standard input. Only the irak prompt runs the startup file and keeps history.
_Avoid_: REPL, interactive irak, interactive mode.

<a id="irak-submission"></a>**irak submission**:
The text entered at the irak prompt and evaluated as a unit: one line, or several when
the first is incomplete and irak asks for more with its continuation prompt. The `[N]`
in the prompt counts submissions.
_Avoid_: line, statement, command, cell.

<a id="irak-topic"></a>**irak topic**:
At the start of an irak submission, `$_` holds the value of the previous submission, so a
leading dotty subscript reaches into it. When the submission's output comes from
external commands, `$_` is what they wrote to standard output, as a string. A submission
that fails, returns `Nil`, or prints output from Raku code (`say`) leaves `$_`
unchanged, and so does a
[topic-keeping submission](#topic-keeping-submission), or any submission but a
[topic-setting submission](#topic-setting-submission) while the topic is
[pinned](#pinned-topic).

<a id="pinned-topic"></a>**pinned topic**:
The [irak topic](#irak-topic) while submissions do not update it. A lone `-` on the
line of a fresh submission pins the topic, or unpins it if it was pinned; it is not
itself a submission. While pinned, only a topic-setting submission or `!!n` changes `$_`.
_Avoid_: frozen topic, locked topic.

<a id="topic-keeping-submission"></a>**topic-keeping submission**:
An irak submission written with a leading `- `: the prefix is dropped, the rest runs and
its value is shown, but `$_` stays the same, so `- .a`, `- .b` explore one value in turn.
_Avoid_: peek, dry run.

<a id="topic-setting-submission"></a>**topic-setting submission**:
An irak submission written with a leading `! `: the prefix is dropped, and its value
becomes `$_` even while the topic is [pinned](#pinned-topic), which stays pinned on the
new value.
_Avoid_: forced submission, override.

<a id="paging"></a>**paging**:
irak showing an irak submission's output in a pager when it is longer than 5 lines or the
terminal, whichever is shorter. When the pager quits, a two-line summary stays at the
prompt: the output's format and size, then the start of its first line. Errors and the
output of external commands are never paged.
_Avoid_: scrolling, more.

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

<a id="selector"></a>**selector**:
The key or index that follows the `.` of a dotty subscript: `name` in `.name`, `1` in
`.1`, `'foo bar'` in `.'foo bar'`, `~expr` in `.~expr`. A chain such as `%h.a.1.name`
has one selector per dot.
_Avoid_: subscript word, field, accessor.

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
The file or URL the operator is attached to. It is a naked string, a quoted string, or a
variable.
_Avoid_: filename argument, path expression, output file.

<a id="url-target"></a>**URL target**:
A redirection target that names an `http://` or `https://` resource. Loading it reads
the resource (GET); output redirection to it sends the statement's output (POST), and the
statement's value is then the server's response.
_Avoid_: endpoint, remote file.

<a id="bare-host"></a>**bare host**:
A naked load target that starts with a host name and no scheme, read as an `https://`
URL target: `<api.github.com/users/octocat`. The host's last label must be a
top-level domain, and the host must have three labels or more or be followed by a path,
so `<README.md` and `<example.com` stay files. `<./api.github.com` names the file.
_Avoid_: schemeless URL, implicit URL.

<a id="load"></a>**load**:
The suffix form `LVALUE <target`: the target's content, decoded by its format, is assigned
to the left-hand side, which can be anything assignable (`my %cfg <cfg.json`). A bare
`<target` with nothing on the left loads into the topic `$_`. Unlike input redirection,
the standard input stream is not involved.
_Avoid_: slurp-assign, suffix input redirection.

<a id="format"></a>**format**:
How a redirection target's content is decoded and encoded, chosen from the target's
extension, ignoring case (`.json`, `.jsonl`), or, for a URL target, from the media type
the server declares. A target whose extension has no format is plain text.
_Avoid_: codec, file type, serializer.

<a id="capability"></a>**capability**:
That a command reads a format on its standard input, or emits one on its standard
output: `jq` reads JSON, `yq` reads and emits YAML. A pipeline uses capabilities to pick
how a value is encoded for the command it feeds.
_Avoid_: format support, protocol.

<a id="command-catalog"></a>**command catalog**:
The record of external commands' capabilities: shipped defaults, merged with the
user's own entries.
_Avoid_: registry, command database.

<a id="tag"></a>**tag**:
The mark in a YAML file that says what type a value has: `!filesize 1500`,
`!!timestamp 2026-01-02T03:04:05Z`. rak reads and writes nushell's tags and maps each to
a Raku type; an untagged value gets its type from YAML's own rules.
_Avoid_: annotation, type hint.

<a id="text-mode"></a>**text mode**:
How output redirection behaves when the statement prints: the printed text is what goes to
the target. If the target has a format, that text must decode in it, and is re-encoded in
standard form.

<a id="value-mode"></a>**value mode**:
How output redirection behaves when the statement prints nothing and the target has a
format: the statement's value is encoded and written.

<a id="pipeline"></a>**pipeline**:
A sequence of pipeline stages joined by pipes, in which the output of each stage is the
input of the next.

<a id="pipeline-stage"></a>**pipeline stage**:
One element of a pipeline: either an external command, which reads and writes bytes, or
a rak routine, method or block, which reads and writes values without starting a
process. A stage that emits several values produces a lazy `Seq`, or a `Supply` when the
stream is asynchronous.
_Avoid_: filter, step, command (for a rak stage).

<a id="pipe"></a>**pipe**:
The operator joining two pipeline stages, spelled `|` in shell syntax. In plain
syntax, `|` keeps its Raku meanings (the `any` junction infix, the slip
prefix), so the syntax, not spacing, decides what `|` is; there the pipe is
spelled `|-`. Values pass between
rak stages unchanged; where an external command meets a rak stage, bytes become lines
(or decoded values when a format is given) and values become text (or are encoded in a
format). Unlike redirection, a pipe connects stages rather than attaching a statement
to a redirection target.
_Avoid_: redirection, feed.

<a id="formatter"></a>**formatter**:
The pipeline stage spelled as a lone `.`, which shows its input as indented JSON. It is a
[topical command](#topical-command).
_Avoid_: pretty-printer, json command, jq.

<a id="topical-command"></a>**topical command**:
A command whose input is the value piped into it or, used alone, the topic `$_`, such
as `select`, `drop` and the formatter. Builtins and user routines alike become one by a
trait on their declaration; inside it, `$_` is the input. Text from an external command
reaches it as lines until a decode stage decodes it, unless the command declares a
[capability](#capability) to read a format.
_Avoid_: jsoner, filter, data command.

<a id="table"></a>**table**:
A list of hashes, shown as a grid with one row per hash and one column per key. irak
shows a submission whose value is a table this way, as nushell does.
_Avoid_: record list, list of records, dataframe.

<a id="cell"></a>**cell**:
One value of a hash in a table: where a row meets a column. How a cell is shown
depends on its type, so a file size shows as `1.2 MB` and a date as `10 months ago`.
_Avoid_: field, record value.

<a id="filesize"></a>**filesize**:
A number of bytes that keeps its unit: it shows in metric units by default (`1.2 MB`)
and mixes in arithmetic only with other filesizes and plain numbers as nushell
allows, so `1kb + 1` is an error.
_Avoid_: byte count, size (for the type).

<a id="unit-literal"></a>**unit literal**:
A number written touching a unit, as in nushell: `10mb` and `1kib` are filesizes,
`90sec` and `2day` are durations. Plain Raku reports such a word as "two terms in a
row", so the spelling is free in rak mode.
_Avoid_: suffixed number, quantity.

<a id="huff"></a>**huff**:
To give a construct a spelling whose length fits how often it is used, after Huffman
coding: frequent constructs get short spellings. rak huffs Raku constructs that are
frequent in conversation at the command line (`say foo` for `say 'foo'`, `%h.name` for
`%h<name>`).
_Avoid_: huffmanize, abbreviate, sugar.

<a id="unhuff"></a>**unhuff**:
To give a rare construct a longer spelling, freeing its short one for a more frequent
construct. In rak mode, `.5` means `$_[5]`, so the number is written `0.5`.

<a id="dwim"></a>**dwim**:
Do What I Mean: to read a construct the way its writer most likely meant it, rather than
the way a strict rule would. One of Larry Wall's design principles for Perl and Raku. rak
dwims where Raku reports an error: `say foo` prints `foo` instead of failing with an
undeclared routine.
_Avoid_: guess, magic, heuristic.

<a id="verb"></a>**verb**:
To use a noun as a verb, as English does freely (to table a motion, to google a name).
This glossary verbs [huff](#huff) and [topic](#topic): one short verb replaces a phrase.
_Avoid_: verbify, verbalize.

<a id="topic"></a>**topic**:
To make a value the topic `$_`, so the code that follows can leave it unsaid, as a
speaker leaves the subject of a conversation unsaid once it is established. The verb
[verbs](#verb) and [huffs](#huff) topicalization, a term of linguistics Larry Wall
borrowed for Perl's `$_`. rak topics more than Raku: the
[irak topic](#irak-topic) carries each submission's value to the next, a leading dotty
subscript reaches into `$_`, and a [topical command](#topical-command) used alone works
on `$_`.
_Avoid_: topicalize, set the topic.
