# rak cheat sheet (for Raku programmers)

rak is Raku with a shellish surface syntax.
It supports raku sigils.
It includes features inspired by nushell and jq.

Everything you know from Raku still
holds unless a line below changes it. Words in **bold** are defined in
[GLOSSARY.md](../../GLOSSARY.md).

## Turning it on

| How | rak mode? |
|---|---|
| `./rak file.rak` | yes |
| `./rak` (REPL), `./rak -e '…'`, stdin | yes. This is **irak**. |
| any `file.rak`, run by `./rak` | yes |
| `.raku`, `.rakumod`, `.pm6` files, even when run by `./rak` | no, plain Raku |
| `RAKUDO_RAK_FRONTEND=1 RAKU_RAK_MODE=1 rakudo-m …` | same as `./rak` |

The file extension decides. A file with no extension falls back to
`RAKU_RAK_MODE`. Modules you `use` from a `.rak` file stay plain Raku.

### Environment variables

| Variable | Effect |
|---|---|
| `RAKUDO_RAK_FRONTEND=1` | `rakudo-m` compiles with the rak frontend (`Rak::Grammar`, `Rak::Actions`). A `.rak` file is then in rak mode. |
| `RAKU_RAK_MODE=1` | A source with no file extension (`-e`, stdin, the REPL) is in rak mode. Ignored by the default legacy frontend, so pair it with `RAKUDO_RAK_FRONTEND=1`. |

`./rak` sets both. Without them, `rakudo-m file.rak` uses the legacy frontend and
the file fails to compile as rak. `RAKUDO_RAKUAST=1` (upstream's RakuAST
frontend) also honours both gates for now, until the rak code is removed from it.

## At a glance

| Raku | rak |
|---|---|
| `say 'foo'` | `say foo` (naked string) |
| `f 'a', 'b'` | `f a b` (juxtaposed words are separate arguments) |
| `%h<name>` | `%h.name` |
| `@a[1]` | `@a.1` |
| `%h{'a b'}`, `%h{"$k"}` | `%h.'a b'`, `%h."$k"` |
| `%h{$k}` | `%h.~k` (with `my ~k`) |
| `@a[$i]` | `@a.#i` (with `my #i`) |
| `$_<name>`, `$_[1]` | `.name`, `.1` |
| `$obj.meth` (no arguments) | `$obj->meth` |
| `.meth` (on `$_`) | `->meth` |
| `$obj.$meth`, `$obj.&f` | `$obj->$meth`, `$obj->&f` |
| `$obj.meth(1)`, `$obj.meth: 1` | unchanged |
| `my str $s` / `my int $n` | `my ~s` / `my #n` |
| `{ my $*OUT = open 'f', :w; say 1 }` | `say 1 >f` |
| `spurt 'f.json', to-json @a` | `@a >f.json` |
| `my %h = from-json slurp 'f.json'` | `my %h <f.json` |

## Words: routine calls and naked strings

An unquoted word that names a routine already known *at that point in the file*
(your own `sub`s or built-ins) calls it. No parentheses are needed: the words
after it are its arguments.

```rak
sub double($x) { $x * 2 }
say double 3                  # 6
say uc hello                  # HELLO
```

Any other word is a **naked string**: a `Str` literal. That applies to a word that
starts with a letter or `_`, contains no whitespace, and is **not**:

- a keyword (`if`, `given`, `return`, …),
- a routine or variable already known at that point,
- followed directly by `(` (that is always a call, even before the declaration).

```rak
say foo                       # foo
say foo; sub foo { 42 }       # foo  (foo not yet declared)
sub foo { 42 }; say foo       # 42   (foo is known: it is called)
say bar(1); sub bar($x) { $x + 1 }   # 2
say log123                    # log123
```

Juxtaposed words are separate positional arguments, as in a shell:

```rak
sub n(*@a) { @a->elems }
n foo bar baz                 # 3
n foo, bar baz                # 3: commas mix in
n (1 + 3) things              # 2: a parenthesised term, then a word
n toto eq toto                # 1: a word infix still wins
$x = n foo bar if 0           # `if` is a statement modifier, not a word
```

## Spacing is syntax

Binary operators are written with spaces around them. An operator that touches
the next word is redirection, not an infix:

```rak
$a > $b        # comparison
say x >out     # redirection
@a >>+<< @b    # hyperoperator (spaced), not an append
```

## New sigils: `~` (native `str`) and `#` (native `int`)

```rak
my ~s = "hello";   my #n = 5;
~s ~ '!'           # ~s reads the variable
"hi ~s, n=#n"      # both interpolate in "…"
my ~e;  my #z;     # defaults are "" and 0, never undefined
sub f(~x, #y) { … }
```

- The sigil is the type. `my Str ~s`, `my int #n` and `is Int` are compile errors.
- `where` and `state` fail, the same way they fail on Raku's `str` and `int`.
- `~foo` with no space is the variable, not "stringify `foo()`". Write `~ foo()` or `foo()->Str` for the old meaning.
- `#` followed by an identifier is a variable, not a comment. Comments need a space
  or a non-identifier character: `# note`, `#----`. An undeclared `#oops` is a
  compile error.
- Unaffected: `~42`, `'a' ~ 'b'`, `~~`, `~=`, `$~MAIN`.

## Dotty subscripts

`.` followed by a plain thing subscripts. It does not call a method.

| rak | Raku |
|---|---|
| `%h.name` | `%h<name>` |
| `%h.'a b'` | `%h{'a b'}` |
| `%h."$k"`, `%h."id-{~n}"` | `%h{"$k"}`, `%h{"id-{~n}"}` (interpolates) |
| `@a.1` | `@a[1]` |
| `%h.~k` | `%h{~k}` |
| `@a.#i` | `@a[#i]` |
| `%h.toto.#i` | `%h<toto>[#i]` |
| `@a.1.0`, `%h.users.1.name` | `@a[1][0]`, `%h<users>[1]<name>` |

They stack, and all of them are lvalues: `%h.x = 3`, `@a.0 = 9`, `@a.1.1 = 9`.

`%h.$key` is an error. Write `%h."$key"` for a subscript by a `$` variable,
and `%h->$key` for Raku's indirect method call.

Quoted keys are for keys that aren't identifiers, like jq's `."key"`. jq has
no `.'key'`. With arguments, `."name"(…)` and `.'name'(…)` stay Raku's quoted
method name call.

### Method calls

```rak
Foo->new            # parameterless call: use ->
$f->bar->baz
$f.baz(5)           # with arguments, . still calls
$f.baz: 5
%h.keys()           # empty parens also call
$x->$meth           # indirect call: Raku's $x.$meth
$x->&f(1)           # Raku's $x.&f(1)
$_->&f              # on the topic: a leading ->&f is a pointy block
```

`.$var`, `.@var` and `.&var` are compile errors that name the `->` spelling.

`@a->[0]`, `->{…}` and `->(…)` stay Raku's obsolete-syntax error.
`-> $x { }`, `->$x { }` and `->Int $x { }` are still pointy blocks.

### On the topic

With nothing before it, the dotty form applies to `$_`:

```rak
given { a => 1, b => [5, 6] } {
    .a          # $_<a>
    ."a"        # $_{"a"}
    .b.1        # $_<b>[1]
    ->elems     # $_.elems
    .keys()     # still a method call
}
.5             # in rak, .5 is $_[5]. Write 0.5 for the number.
```

## Redirection

Three forms: **output redirection** (`STMT >file`, `STMT >>file`), **input
redirection** (`<file STMT`) and **load** (`LVALUE <file`, or `<file` alone).
The operator touches its target, which is a naked string, a quoted string or a
variable. A naked target that starts with a digit (`>123.txt`) is not a target,
except for a load: `$a <5` loads the file `5` and warns at compile time. Write
`$a < 5` to compare.

| Form | Meaning |
|---|---|
| `STMT >file` | **Output redirection**: bind `$*OUT` to `file` (truncated) for this statement only. |
| `STMT >>file` | The same, but appending. |
| `<file STMT` | **Input redirection**: bind `$*IN` to `file` for this statement only. |
| `LVALUE <file` | **Load**: decode `file` and assign it to the left-hand side. |
| `<file` (on its own) | Load into `$_`. |

```rak
say foo >out.txt              # "foo\n"
print foo >out.txt            # "foo": the routine keeps its own behaviour
print 'a', 'b' >>log.txt
note oops >x.txt              # stderr is not captured; x.txt is empty
for 1..3 { say $_ >>n.txt }   # the outer $_ is visible
<in.txt say $*IN->slurp
<in.txt $n = $*IN->lines->elems
```

- The binding ends with the statement. The file is flushed and closed afterwards,
  even when the statement throws.
- An unwritable target or a missing input file throws an error that names the file.

### Formats (`.json`, `.jsonl`, case-insensitive)

A target's extension picks its **format**. Any other extension is plain text. With
`>$var`, the format is chosen at run time.

**Value mode**: the statement prints nothing, so its value is encoded.

```rak
@a >a.json          # pretty JSON: 2-space indent, sorted keys, trailing \n
%h >h.json
$x >x.json          # "hi"
1/3 >r.json         # 0.3333333333333333
@a >a.jsonl         # one compact record per element
%r >>r.jsonl        # appends one record
$x >x.txt           # plain target + no output = empty file
```

**Text mode**: the statement prints, so the printed text must be JSON. It is then
re-encoded in standard form. Relaxed input (unquoted keys, single quotes, trailing
commas) is accepted.

```rak
print q[{ a: 'a', }] >t.json   # {\n  "a": "a"\n}\n
say @a >t.json                 # dies: the gist "[1 2 3]" is not JSON
```

**Load**:

```rak
my @a <a.json        # needs a JSON array
my %h <h.json        # needs a JSON object
my $x <any.json      # takes anything
%h<data> <a.json     # any lvalue works
my @l <f.txt         # plain text: lines
my $s <f.txt         # plain text: the whole string
my @r <r.jsonl       # array of records ($ gives the same array)
<data.json; say .users.1.name
```

**Errors** (all are `X::Rak::Format`):

| Exception | Cause |
|---|---|
| `X::Rak::Format::Encode` | The value has no JSON form (`Set`, `Inf`, …). The target is left untouched. |
| `X::Rak::Format::Decode` | Bad JSON. The message names the file and the line, and the target is left untouched. |
| `X::Rak::Format::Shape` | Wrong sigil for the content, e.g. `my %h <array.json`. |
| `X::Rak::Format` | `>>file.json`. Appending JSON is refused; use `.jsonl`. |

### URL targets (`http://`, `https://`)

A load from a URL is a GET, and `>url` is a POST of JSON. A naked URL
interpolates `$name`; anything more complex goes in double quotes.

```rak
my %u <https://api.github.com/users/$user    # GET, JSON by Content-Type
<https://api.github.com/repos/rakudo/rakudo; say .stargazers_count
my %r <"https://api.github.com/{$path}?per_page=5"
my %i = title => 'Test'
%i >https://api.github.com/repos/OWNER/REPO/issues   # POST; value: the new issue
echo '{"body": "hi"}' >https://…/comments           # a command's output, POSTed
```

- The response's media type picks the format: `application/json` or any `+json` is
  JSON; anything else is text. An empty response (`204`) gives `Nil`.
- The statement's value is the decoded response, not the value sent (ADR 0005).
- `>>url`, `<url STMT`, `2>url` are compile-time errors.
- A load may drop `https://` (a [bare host](GLOSSARY.md#bare-host)) when the host
  ends in a TLD and has three labels or a `/` after it: `<api.github.com/zen`,
  `my %r <github.com/rakudo`. `<README.md`, `<example.com`, `<'a.b.com'` and
  `<./api.github.com` are files; so is any `>` target.
- A 4xx or 5xx response, or a failed connection, throws `X::Rak::HTTP`
  (`.status`, `.reason`: the JSON `message`, or the first line of the body).
- Headers come from `~/.config/rak/http-headers.json` (relaxed JSON), keyed by host.
  A value `$NAME` is that environment variable; `auth:` means `Authorization: Bearer`.
  With nothing configured, `api.github.com` uses `gh auth token`.

```json
// ~/.config/rak/http-headers.json
{ 'api.github.com': { auth: '$GITHUB_TOKEN', 'X-GitHub-Api-Version': '2022-11-28' } }
```

Requests go through `curl`; without it, through `HTTP::UserAgent` (Rakudo Star).

## irak (the REPL)

```
$ ./rak
Welcome to irak, the rak shell.
[0] > {a => 1, b => [5, 6]}
[1] > .b               # $_ is the previous value
[5 6]
[2] > .1
6
[3] > ->succ
7
[4] > <data.json       # loads into $_ for the next line
```

ENTER twice runs a line. The first ENTER shows how irak reads it:

- it inserts `my` before the first use of an undeclared variable (`$x = 1`
  becomes `my $x = 1`), except in a string or for a likely typo;
- it colors each word: keyword, routine, command, naked string, or undeclared.

A second ENTER on the same line within a second runs it. An empty or unfinished line,
`!n`, and input that is not a terminal run on the first ENTER. `NO_COLOR` turns the
colors off.

`$_` holds the value of the previous submission. A submission that fails, returns
`Nil` or prints output leaves `$_` unchanged. So does one starting with `- `: the
prefix is dropped, the value shown, and `$_` kept, to look around in it.

```rak
[0] > { a => { b => 42 }, c => 7 }
[1] > - .a          # {b => 42}; $_ is still the hash
[2] > - .a.b        # 42
[3] > .c            # 7, and now $_ is 7
```

Recalling submissions (only when the directive is the whole line; n is the
prompt number, the last 1000 are kept):

| Input | Effect |
|---|---|
| `!n` ENTER | re-runs submission n |
| `!n` TAB | puts submission n's source in the edit buffer |
| `!!n` | sets `$_` to submission n's value |
| ↑ / ↓ | history, stops at both ends |
| `!p` | pages the last output again |

Output longer than 5 lines (or the terminal) goes to a pager, `less -R` unless
`RAK_PAGER` or `PAGER` says otherwise; an empty `RAK_PAGER` turns paging off.
When the pager quits, a summary stays: format, lines and size, then the start of
the first line. Errors, `$*ERR` and external commands are never paged.

## Commands

A statement whose first word is followed by more words runs a command; so does a
lone word naming a program on `$PATH`.

```rak
ls -l @files "my file" {1+1}   # external command; @files gives one argument each
^sort data.txt                 # ^ forces the external command over rak's sort
my $out = ls                   # $out and $_ set to 'ls'
my $out = (ls)                 # value used: standard output of ls command captured as a Str
~(pwd)                         # same, in a contextualizer
say $? == 0, $?->exitcode      # $? is the last exit status, a Proc
make 2>err >out >>log <in 2>&1 # redirections, touching their target
```

In arguments, a leading `/` starts a naked path and `m/` starts a regex; write
`./m/x` for a relative path named `m/…`.

Builtins:

| Builtin     | Effect                                             |
|-------------|----------------------------------------------------|
| `cd dir`    | change `$*CWD` and the process directory           |
| `cd`        | go to `$*HOME`                                     |
| `cd -`      | go back to the previous directory                  |
| `type name` | list every meaning of `name`, marking the one that wins |

A non-zero exit status fails a `.rak` file; irak shows it.

## Pipelines

A statement that starts with a command, a load (`<file`) or a leading dotty
subscript is a pipeline when a spaced `|` follows. Commands and rak stages mix.

```rak
^printf 'b\na\nb\n' | ^sort | ^uniq -c   # commands: a Unix pipe
git log --format=%an | ->unique         # a command's output is a Seq of lines
<data.json | .users | map *.name;       # rak stages only, as in jq
curl -s $url | from-json | .items;      # decode: from-json, from-jsonl
curl -s $url | .                        # show as indented JSON, like jq .
.users | ^wc -l                         # values to a command: one line each,
                                        #   hashes as JSON Lines
say +$?, +@?                            # first failure (else last); every command
```

| Stage | Gets the input as |
|---|---|
| command | standard input |
| `->meth args` | `input.meth(args)` |
| `.path` | `input.path` |
| `{ block }` | `$_` |
| `name args` | the last argument, as with `==>` |
| `.` | shown as JSON |

A lone `.` is the formatter: on its own it shows the topic `$_` as indented JSON,
colored on a terminal. Text input is read as JSON, else as rak data literals
(`{ :a, b => 1 }`), else as one string.

In irak, a load that decodes JSON shows its value the same way, so
`<api.github.com/users/octocat` needs no `.` after it.

Each stage gets the whole input, not one value at a time: use `map` for that.

## Gotchas

- `.5` is `$_[5]`, not a number. Write `0.5`.
- `<a b>` word lists work at the top level (`my @x = <a b c>`), but fail to
  compile inside `(…)` or `[…]` with "Unexpected closing bracket":
  `[<a b>, <c d>]` breaks. Use `qw` or quotes there.
- `foo` is a string until `sub foo` has been parsed. Declare routines before you
  call them without parentheses, or call them with `foo(…)`.
- `.meth` without parentheses is now a subscript. When porting Raku, change it to
  `->meth`.
- `.$meth` and `.&f` are errors. When porting Raku, change them to `->$meth` and
  `->&f`.
- `@names | ^sort` is a junction, not a pipeline: only a command, a load or a
  leading dotty starts one. Write `$_ = @names; .[] | ^sort`.
- In a pipeline a spaced `|` is the pipe. For a junction there, write it
  unspaced (`1|2`) or in parentheses (`(1 | 2)`). `any(1, 2)` as a stage gets the
  input as its last argument.
- `map .name` calls `.name` on `$_` right away. Write `map *.name` or
  `map { .name }`.
- A pipeline ending in a rak stage needs its `;` at the end of the line, like any
  rak statement; only a command ends at the newline.

## Planned, not implemented

Planned in `PLANS/`, not available yet: `alias`,
globbing, indentation in place of braces, sigilless
one-letter variables (`i`, `s`, …), a `^` sigil for native `num` (unsettled), YAML and myaml data
pattern matching, `has ~.x` / `has #.x` attributes, and `#n.WHAT` autoboxing.
