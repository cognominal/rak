# Dotty subscripts

Status: WIP — implemented, including quoted keys (`.'k'`, `."k"`) and the indirect method
call `->$var` / `->&f`.

A [dotty subscript](../../GLOSSARY.md#dotty-subscript) spells a subscript without brackets:
`@a.1.toto.~str.#int` is `@a[1]<toto>{~str}[#int]`. The full list of forms is in the
[cheat sheet](../../rak-docs/CHEATSHEET.md#dotty-subscripts); this document explains the design.

Raku's `.[]` postcircumfix is not overloaded to reach hashes: `.` decides between `[…]`
and `{…}` from what follows it, at parse time, so the subscript stays as unambiguous as
in Raku.

`~` and `#` aren't just a nicer way to declare typed variables. Their
real payoff is **bracketless subscripting**, because their sigil alone
guarantees the value's type, so the parser can desugar unambiguously
*at parse time* — no runtime type check, no FALLBACK method.

## Walking data, à la jq

Dotty subscripts (`%h.users.1.name`, `.b.1` on the topic) and `->meth` for method calls
(`->$meth` for an indirect one) give the short paths of jq inside a full language. jq's
`."key"` for keys that aren't identifiers works too, and interpolates (`%h."user-$id"`);
rak adds the literal `.'key'`, which jq lacks. Text pipelines break down as soon as data
is nested; paths do not.

## The problem `~`/`#` solve

Raku already lets a variable drive a subscript, but only with explicit
brackets: `.%h{$key}` / `.[$idx]`. A bare `$`-sigiled variable carries
no static type information — the parser can't know whether to emit
positional `[...]` or associative `{...}` access without a runtime check.

`~foo` is provably a string → associative subscript `{...}`.
`#bar` is provably an integer → positional subscript `[...]`.

## How `.` chooses the subscript

After a term, what follows `.` picks the subscript kind: an integer or `#expr` gives a
positional `[…]`; an identifier, a quoted key or `~expr` gives an associative `{…}` or
`<…>`. The cheat sheet's table lists every form. `^expr` has no kind: the float sigil
itself is [unsettled](../unsettled.md) (see below).

## `->` for parameterless method calls

Because `.name` now means `<name>` (a literal associative key lookup),
parameterless method calls move to `->name`:

```raku
@a->elems          # was @a.elems — call method elems with no args
@a.elems           # now means @a<elems> — subscript by literal key "elems"
@a.elems()         # still a method call (parentheses make it explicit)
@a.elems: sort     # still a method call with adverb (colon disambiguates)
```

`->$var` and `->&f` make Raku's indirect method call. `.$var` and `.&f` are errors in
rak mode, because they would read as subscripts. All of this applies in rak
mode only: `.rakumod`, `.raku` and `.pm6` files keep standard Raku semantics.

## Why `~`/`#` are the prerequisite

Without fixed-type sigils, you can't write `.~foo`/`.#foo` without
brackets — the parser needs to decide `{}` vs `[]` before runtime, and
only a sigil that *guarantees* the type (str vs int) provides that
information. `~` and `#` are the first two; `^` for float would be the
natural third.

## Reading a missing path (planned)

Reading `a.1.name` when `a[1]` does not exist should not create it: no autovivification
on read. irak may allow it, so a structure can be built up interactively. With
[one-letter variables](sigils.md#one-letter-variables-without-a-sigil-planned), the sigil
of `a` could also be left out where it can be inferred.

## What about `^` in the dotty sugar?

A float sigil `^expr` could desugar to either subscript kind depending
on use case. Likely candidates:

| Interpretation | Meaning |
|----------------|---------|
| `[^idx]`       | positional, using a float as an index (truncated to int) |
| `{^key}`       | associative, using a float as a key (stringified or exact) |

The most consistent answer: since `#` (int) takes the positional branch
and `~` (str) takes the associative branch, a float could follow
`#`'s pattern (positional, since `num` is numeric like `int`), or a
separate rule could reserve it for a future float-keyed collection.
The rak branch explicitly leaves "sigils for other types" out of MVP;
`^` would be designed when there's a concrete use case for it in the
dotty sugar.

