# Highlighting rak code

rak code is highlighted by what each word *denotes*, not by its token type. In rak the
same word can be a keyword, a routine call, an external command or a naked string,
depending on its context and on what is declared before it
([naked strings](features/naked-strings.md)). The highlighting shows the reading the
compiler will make, so a word that does not mean what the writer meant stands out
before anything runs.

Status: WIP, NEEDSPEC — the convention is implemented in irak (cognominal/rak#1, branch
`irak-feedback`) and in the terminal cheat sheet. The irak command that shows the
cheat sheet is planned, and the open questions at the end remain.

## The classes

| Class        | Example         | SGR      | Looks like        |
|--------------|-----------------|----------|-------------------|
| keyword      | `if`, `my`      | `1;35`   | bold magenta      |
| routine      | `say`, `lines`  | `36`     | cyan              |
| command      | `ls`, `^grep`   | `1;32`   | bold green        |
| naked-string | `hello`         | `33`     | yellow            |
| undeclared   | `$ctiy`         | `4;31`   | underlined red    |
| variable     | `$x`, `~s`      | `3`      | italic            |
| path         | `/etc`, `>out`  | `34`     | blue              |

- **keyword:** a word of the grammar (`if`, `for`, `my`, `sub`, …), including a `my`
  that irak inserted. The list comes from the grammar (`rak-keywords`).
- **routine:** a word that calls a routine, built in or declared earlier.
- **command:** a word that runs an external command, from its first character (`^` of
  `^grep` included) to the end of its name. Its arguments are not colored.
- **naked-string:** an unquoted word read as a `Str` literal.
- **undeclared:** a variable that is not declared, at each of its occurrences.
- **variable:** a declared variable, with any sigil (rak's `~` and `#` included) and
  twigil (`$*OUT`), and a variable used as a redirection target (`>$f`). A
  contextualizer (`~(pwd)`, `$(…)`) is not a variable.
- **path:**
  - a redirection or load target (`>out`, `>>log`, `2>"e r"`, `<in`), always, quoted
    or not, URL targets included;
  - a command argument that reads as a path: absolute (`/etc`), from home (`~`,
    `~/x`), `.`, `..`, or with a `/` in it (`./a`, `b/c`). A bare `data.txt` is not
    identified: it could be anything.

Everything else keeps the terminal's default color: quoted strings, numbers, operators,
punctuation and comments. Only the classes where rak differs from
what a reader expects get a color; a highlighting of every token would drown them.

## Rules

- **Denotation, not syntax.** The classes come from the parse of the whole text, with
  the declarations in scope: `hello` is a naked string, and a routine once
  `sub hello {}` is declared. When the parse fails, only keywords are colored.
- **The 16 ANSI colors only.** They follow the user's terminal theme, so the colors stay
  readable on light and dark backgrounds. No 256-color or RGB codes.
- **Not by color alone.** keyword and command are bold, undeclared is underlined and
  variable is italic, so they stay apart from the rest for a color-blind reader or on
  a monochrome terminal. A terminal without italic shows variables plain.
- **Each span ends with `\e[0m`.** Spans never nest and never span a line break.
- **`NO_COLOR`.** When the `NO_COLOR` environment variable is set to a non-empty value
  (https://no-color.org), nothing is colored.
- **One table.** The classes and their codes are defined once, in `%irak-sgr`
  (`src/core.c/REPL.rakumod`). Every highlighter uses it.

## Where it applies

### irak

The first ENTER rewrites the line (inserting `my`) and colors it; see
[irak](features/irak.md) and the cheat sheet. The spans come from
`REPL.irak-feedback`, as `from`, `to` and `class` offsets into the line. The colors
stay until the line is edited (a known limitation: editing redraws the field without
them).

### The terminal cheat sheet

`rak-docs/CHEATSHEET.ans` is [CHEATSHEET.md](../rak-docs/CHEATSHEET.md) for the terminal,
with its rak code highlighted. Read it with `less -R rak-docs/CHEATSHEET.ans`.

- **Source:** `CHEATSHEET.md` stays the only source. `make rak-cheatsheet` runs
  `tools/rak-cheatsheet.raku` through the `./rak` wrapper to regenerate the `.ans`, and
  `t/02-rakudo/rak/027-cheatsheet.t` fails when the `.ans` is out of date.
- **The analysis is irak's:** `REPL.irak-feedback` with `:!declare`, which colors
  without inserting `my`, so the examples are shown as written. The codes come from
  `REPL.irak-sgr`.
- **Code blocks** (` ```rak `) are analyzed as one text, so a `sub` declared on the
  first line makes a word a routine on the next ones. A block often holds one-line
  examples with no `;` between them, so when the block does not parse as written it
  is analyzed with a `;` after each line, then line by line, each line after the
  lines before it that parsed.
- **irak sessions** (` ``` ` blocks): only the text after a prompt (`> `,
  `[n] > `) is analyzed, not irak's answers.
- **Inline code**, in prose and in tables, is highlighted when it is a phrase (it
  holds a space), parses, and reads as more than naked strings: `ls -l`, `cd dir`.
  Anything else is bold. Out of context, a lone word would mislead (`NO_COLOR` would
  be a naked string), and so would a placeholder (`name args`, `{ block }`).
- **undeclared** is shown as **variable**: the examples leave out `my`.
- **Placeholders:** in inline code, an all-caps word (`STMT`, `LVALUE`) is not a naked
  string.
- **Lone words** in inline code: one that can only be a variable (`$_`, `$*OUT`,
  `%h`) is italic, one that can only be a path (`/etc`, `./rak`, `~/x`) is blue.
- **Comments** are dim (`2`). This is the one class the cheat sheet adds; irak does
  not color comments. A `#` starts a comment when it follows a space or starts the
  line, is not followed by a letter (that is the `#` sigil), and is not in a string.
- **The rest of the Markdown:** headings bold (levels 1 and 2 also underlined),
  bold stays bold (also across a line break), links are reduced to their text. In an aligned table (its
  separator row padded), each cell is padded back to its source width, so the
  columns stay aligned.
- **`NO_COLOR`:** the file always holds the codes; the planned irak command (`cheat`,
  perhaps `cheat redirection` for one section) strips `\e[…m` when `NO_COLOR` is set.

Making the cheat sheet found two bugs in irak's highlighting, both fixed:

- a signature with two parameters hung the analysis: the Match tree has a cycle
  (`param-sep` holds itself), so each node is now walked once;
- the operands of a list infix (`,` and rak juxtaposition) were not colored: they are
  positional children of the Match, which the walk skipped (`say foo bar` colored
  only `say`).

## Open questions

- Should irak color quoted strings and numbers too, as most editors do? This document
  says no, to keep the five classes visible.
- Should the cheat sheet be rendered for the user's current terminal width rather than
  as written?
- Should the generated `.ans` be committed (as now, so it can be read without a build)
  or only generated and installed?
- Editors (a tree-sitter grammar or a Vim syntax file) cannot know the denotation of a
  word without the compiler. An LSP server built on `irak-feedback` could.
