# The new sigils `~` and `#`

The [new sigils](../../GLOSSARY.md#new-sigils) `~` and `#` declare a native `str` and a
native `int`. How to use them is in the
[cheat sheet](../docs/CHEATSHEET.md#new-sigils--native-str-and--native-int); this document
explains why they exist, what they cost, and what comes next. Their main purpose is to
drive [dotty subscripts](dotty-subscripts.md).

Status: `~` and `#` are implemented. A `^` sigil for native `num` is unsettled: whether
to add it, and how it subscripts, are both [open](../unsettled.md). One-letter variables
without a sigil are planned, but their letter-to-type table is unsettled too.

## Boxing, Scalars, and why rak sigils skip them

### The cost of `$`

In standard Raku, every `$`-sigiled variable is backed by a `Scalar`
container object — a "box" that wraps the value. That box enables
useful things:

| Capability     | What it enables                                          |
|----------------|----------------------------------------------------------|
| Aliasing       | Two names can share the same storage (`:=`)              |
| `is rw` params | A callee can mutate the caller's variable                |
| Undefined state| Variable can be `Nil`/`Any`; you can test `.defined`     |
| Type flexibility| A `$` variable can hold any type at runtime             |

But the box has real costs:

- **Indirection on every access** — variable → `Scalar` → value, one more
  pointer hop even before touching the data.
- **Allocation on every write** — Raku `Int`/`Str` are immutable, so
  `$sum = $sum + 1` allocates a new object every time.
- **GC pressure** — those short-lived objects must be reclaimed.
- **JIT impedance** — the JIT has to unbox/rebox through the container,
  making it harder to keep values in machine registers.

A native variable (`my int $x`, `my str $s`) skips the box: the value
lives in a raw machine slot. But the `$` sigil hides that distinction —
you can't tell from the variable's *face* which kind it is, and you still
need the explicit type annotation.

### The rak sigils: native by default, no boxing

Rak adds two sigils whose **glyph alone guarantees the machine-level
type** — no `Scalar` container, no explicit type annotation:

```raku
my ~name = "Alice";   # native str — no box
my #age  = 30;         # native int — no box
```

They are wired through the same code path as `my str $x` / `my int $x`
in the Rakudo compiler (`IMPL-CONTAINER` returns `nqp::null` when
`$of` has a native primitive spec), so they inherit all the benefits
of native scalars:

- **No container indirection** — a `~`/`#` variable is a raw lexical slot.
- **No per-operation allocation** — `#n + 1` is a machine `add` producing
  another machine word; no GC churn.
- **~13× faster in tight loops** — benchmarked against boxed `Int`
  (30M increments: ~0.034s for `#sum` vs ~0.45s for `Int $sum`).
- **JIT-friendly** — the JIT keeps a native local in a register across
  iterations and emits a tight native op. The boxed version forces
  unboxing/reboxing speculation.
- **No overflow/representation branching** — machine `int` is fixed-width;
  boxed `Int` checks every operation whether the result still fits fixnum
  or must promote to bignum.

Because the sigil *is* the type, explicit type annotations are a
compile error:

```raku
my Str ~name = "Alice";   # COMPILE ERROR: ~ already implies Str
my int #age  = 30;        # COMPILE ERROR: # already implies int
my Int #age  = 30;        # error too, even the "boxed" Int
```

`where` constraints were meant to keep working, since they add a runtime check rather
than a type, but they currently fail the same way they fail on Raku's `str` and `int`.

### Why native values, not boxes?

The entire reason `~` and `#` exist is to drive subscripting ([dotty subscripts](dotty-subscripts.md)).
A subscript **reads** a key or index once to decide where to look;
it never needs to:

- write back through the subscript expression itself,
- keep a live alias to the variable that supplied the key, or
- hand the key off expecting mutation-by-reference.

So the `Scalar` container's whole purpose — aliasing, rebinding,
rw-by-reference — is dead weight for this use case. A plain native
value is not a compromise; it's the right-sized tool. If you genuinely
need aliasing, `is rw`, or undefined state, that's what `$` with an
explicit type is for.

### What you give up

- **No `Nil` / undefined state** — `~s` defaults to `""`, `#n` to `0`.
- **No aliasing (`:=`)** — `~a := ~b` is not supported.
- **No `where` constraints yet** — they fail on Rakudo's native scalars too.
- **No `state` variables** — inherited from Rakudo's native-scalar
  limitation (`state str $x` is NYI, so `state ~x` is too).
- **No `is rw` parameters** on `~`/`#` — they can't be passed by
  reference to mutate the caller's variable.

## The `~` sigil — native `str`

```raku
my ~name = "Alice";
~name = "Bob";             # reassign, same as any variable
say "Hello, ~name!";       # interpolates in qq strings
```

Mnemonic: `~` is already Raku's string-flavoured operator
(concatenation `$a ~ $b`, stringify prefix `~$x`). A `~`-sigiled
variable is "the string one."

Grammar detail: bare `~identifier` always means the sigil, never the
prefix stringify operator. Write `~ foo` (space) or `~(foo)` if you
need the old bareword-stringify reading. `~$x`, `$a ~ $b`, `~~`, `~=`
are all unaffected.

## The `#` sigil — native `int`

```raku
my #count = 0;
#count = #count + 1;       # machine add, no boxing
loop my #i = 0; #i < 10; #i++  { ... }
```

Mnemonic: `#` conventionally means "number/count" (item #3, #items).
A `#`-sigiled variable is "the number one."

**Comment change:** Because `#` can now start a term, a plain `#`
followed by a letter or underscore with **no space** is a variable
reference, not a comment. `# this is fine` (space); `#TODO: fix` now
looks like the variable `#TODO`. Add a space after `#` for comments.
`` #`(...) `` and `#|`/`#=` are unaffected.

## Proposed `^` sigil — native `num` (float)

Status: **unsettled.** Nothing is implemented, and it is not decided whether to add the
sigil at all. See [unsettled](../unsettled.md).

Following the same pattern, a natural next sigil is `^` for native
float (IEEE 754 `num`):

```raku
my ^pi     = 3.14159;         # native num, no box
my ^radius = 5.0;
say 2 ^ ^pi * ^radius;        # infix ^ (exponentiation) is spaced both sides;
                               # bare ^pi touching → the sigil
```

**Why `^` is a good fit:**

- **`^` already means "float" in Raku** — `num` (native float) is
  displayed as `^` in `.raku` output. The association "caret = float"
  is already culturally wired.
- **No term-position collision** — prefix `^` (hyper meta-operator)
  requires a space or `(...)` to start a term; `^foo` touching an
  identifier is unclaimed grammar. Same disambiguation rule as `~`:
  touching → sigil, space → old meaning.
- **Twigil `$^` is an existing, separate feature** — `$^foo` (dynamic
  variable twigil) is a different grammatical position (after `$`,
  not at term start), so no collision.
- **Mnemonic:** `^` "points up" like a decimal point, and it's
  the exponentiation operator — float territory.


## About the benchmark

The ~13× figure comes from one microbenchmark: 30 million increments, on this branch's
MoarVM build with the JIT on. `my int $sum` measures the same as `#sum`, which confirms
that `#` uses the same code path as an explicit native declaration. With the JIT off
(`MVM_JIT_DISABLE=1`) the gap narrows to ~7×, so most of the gain comes from the JIT
keeping the native value in a register. `~` against boxed `Str` has not been measured.
The ratios depend on the loop, the MoarVM version and the machine.

## Why a native `int` is enough for indices

`#` is a machine integer, not an arbitrary-precision `Int`. A dense array whose index
does not fit in 64 bits cannot exist in memory, so this costs nothing for subscripting.
Code that needs huge sparse indices keeps using `$` with brackets (`@a[$big]`).

## One-letter variables without a sigil (planned)

To cut noise further, one-letter variables could drop their sigil, with the letter
deciding the type: `i` to `n` would be integers and `s` a string, as in
`say i for 1..100`. The full letter-to-type table is not designed yet. In particular,
whether capitals (`I` to `N`) mean arbitrary-precision integers, and what `r` to `z`
hold, are open questions. These names would also compete with
[naked strings](naked-strings.md): `say s` must decide between the variable and the
string `"s"`.
