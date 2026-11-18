# rak cheat sheet (for Raku programmers)

rak is Raku with a shellish surface syntax.
It supports raku sigils.
It includes features inspired by nushell and jq.

Everything you know from Raku still
holds unless a line below changes it. Words in **bold** are defined in
[GLOSSARY.md](GLOSSARY.md).

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

## At a glance

| Raku | rak |
|---|---|
| `say 'foo'` | `say foo` (naked string) |
| `f 'a', 'b'` | `f a b` (juxtaposed words are separate arguments) |
| `%h<name>` | `%h.name` |
| `@a[1]` | `@a.1` |
| `%h{$k}` | `%h.~k` (with `my ~k`) |
| `@a[$i]` | `@a.#i` (with `my #i`) |
| `$_<name>`, `$_[1]` | `.name`, `.1` |
| `$obj.meth` (no arguments) | `$obj->meth` |
| `.meth` (on `$_`) | `->meth` |
| `$obj.meth(1)`, `$obj.meth: 1` | unchanged |
| `my str $s` / `my int $n` | `my ~s` / `my #n` |
| `{ my $*OUT = open 'f', :w; say 1 }` | `say 1 >f` |
| `spurt 'f.json', to-json @a` | `@a >f.json` |
| `my %h = from-json slurp 'f.json'` | `my %h <f.json` |

## Naked strings

An unquoted word is a `Str` literal when it starts with a letter or `_`, contains
no whitespace, and is **not**:

- a keyword (`if`, `given`, `return`, …),
- a routine or variable already known *at that point in the file*,
- followed directly by `(`.

```rak
say foo                       # foo
say foo; sub foo { 42 }       # foo  (foo not yet declared)
sub foo { 42 }; say foo       # 42
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
| `@a.1` | `@a[1]` |
| `%h.~k` | `%h{~k}` |
| `@a.#i` | `@a[#i]` |
| `%h.toto.#i` | `%h<toto>[#i]` |
| `@a.1.0`, `%h.users.1.name` | `@a[1][0]`, `%h<users>[1]<name>` |

They stack, and all of them are lvalues: `%h.x = 3`, `@a.0 = 9`, `@a.1.1 = 9`.

`%h.$key` keeps its Raku meaning (indirect method call). It is not a subscript.

### Method calls

```rak
Foo->new            # parameterless call: use ->
$f->bar->baz
$f.baz(5)           # with arguments, . still calls
$f.baz: 5
%h.keys()           # empty parens also call
```

`@a->[0]`, `->{…}` and `->(…)` stay Raku's obsolete-syntax error.
`-> $x { }`, `->$x { }` and `->Int $x { }` are still pointy blocks.

### On the topic

With nothing before it, the dotty form applies to `$_`:

```rak
given { a => 1, b => [5, 6] } {
    .a          # $_<a>
    .b.1        # $_<b>[1]
    ->elems     # $_.elems
    .keys()     # still a method call
}
.5             # in rak, .5 is $_[5]. Write 0.5 for the number.
```

## Redirection

The operator touches its target. The target is a naked string, a quoted string or
a variable. A naked target that starts with a digit (`>123.txt`) is not a target,
except for a load: `$a <5` loads the file `5` and warns at compile time. Write
`$a < 5` to compare.

| Form | Meaning |
|---|---|
| `STMT >file` | Bind `$*OUT` to `file` (truncated) for this statement only. |
| `STMT >>file` | The same, but appending. |
| `<file STMT` | Bind `$*IN` to `file` for this statement only. |
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

`$_` holds the value of the previous submission. A submission that fails, returns
`Nil` or prints output leaves `$_` unchanged.

## Gotchas

- `.5` is `$_[5]`, not a number. Write `0.5`.
- `<a b>` word lists work at the top level (`my @x = <a b c>`), but fail to
  compile inside `(…)` or `[…]` with "Unexpected closing bracket":
  `[<a b>, <c d>]` breaks. Use `qw` or quotes there.
- `foo` is a string until `sub foo` has been parsed. Declare routines before you
  call them without parentheses.
- `.meth` without parentheses is now a subscript. When porting Raku, change it to
  `->meth`.

## Planned, not implemented

Planned in `PLANS/`, not available yet: shell mode (running external commands,
pipes, `alias`, `type`), globbing, indentation in place of braces, sigilless
one-letter variables (`i`, `s`, …), URL redirection targets, YAML and myaml data
pattern matching, `has ~.x` / `has #.x` attributes, and `#n.WHAT` autoboxing.
