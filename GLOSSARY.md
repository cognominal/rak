# rak

The `.rak` frontend of this Rakudo fork: Raku plus a shellish surface syntax. A source
compiled in rak mode gets the extra spellings below; the same text compiled as ordinary
Raku must not.

## Language

**rak mode**:
The language mode a `.rak` source is compiled in, in which naked strings, the dotty
subscript, the new sigils and redirection are available. A source with any other
extension compiles as ordinary Raku, and the feature set must not leak into it.
_Avoid_: rak semantics, shell mode, extended Raku.

**irak**:
An interactive rak session: the execution context in which rak evaluates statements with
no source file (REPL, `-e`, standard input). An execution context, not a mode: its
statements still parse in the standard or shell strategy.
_Avoid_: interactive mode, irak mode, REPL mode.

**naked string**:
An unquoted word that denotes a string literal: it starts with a letter or underscore and
contains no whitespace. A word is not a naked string when it is a keyword (`if`, `given`,
`return` keep their meaning and are never a string), when it names an already-known routine
or variable, or when `(` follows it. "Already-known" is decided as the parser walks the
file, so position matters: `say foo; sub foo { 42 }` prints `foo`, while
`sub foo { 42 }; say foo` prints `42`.
_Avoid_: bareword, unquoted literal, identifier.

**new sigils**:
The `~` and `#` sigils, denoting a native string and a native integer respectively, in
addition to Raku's existing sigils.

**dotty subscript**:
A leading `.` spelling a subscript without brackets: `.name` is the hash subscript
`<name>`, and `.1` / `.~expr` / `.#expr` subscript by an expression. The `->name`
spelling instead calls a parameterless method.
_Avoid_: dot syntax, method sugar.

**redirection**:
A shellish operator attached to a single statement that sends that statement's output to
a file or takes its input from one. The operator is written touching its target, so an
operator with whitespace after it stays an ordinary Raku operator.
_Avoid_: pipe, stream redirect.

**output redirection**:
The suffix form: `STMT >target` writes to the file, truncating it; `STMT >>target`
appends to it.

**input redirection**:
The prefix form `STMT` written as `<target STMT`.

**redirection target**:
The file the operator is attached to. It is a naked string, a quoted string, or a
variable.
_Avoid_: filename argument, path expression, output file.
