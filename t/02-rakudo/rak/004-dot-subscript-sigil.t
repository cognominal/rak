use Test;

# `.~expr` / `.#expr` (a bare `~`/`#`-sigiled variable reference directly
# after `.`, no space) are sugar for `{~expr}` / `[#expr]`. Phase 2 of
# PLANS/archive/subscript-operator.md.
#
# Scope: a bare `~`/`#`-sigiled variable reference only (like `.1` being a
# bare literal), not a general expression starting with `~`/`#`.
#
# The `.~`/`.#` syntax is inside EVAL'd strings, so a compile error is
# reported as one failing test instead of aborting the file.

plan 8;

# `try` keeps a compile-time failure a normal, reported failure for that one
# test, instead of aborting the whole file.
sub try-eval(str $code) { try EVAL($code) }

# --- .~expr: sugar for {~expr} (associative access) ---

is try-eval('my %h; my ~key = "a"; %h{~key} = "hi"; %h.~key'), 'hi',
    '%h.~key reads the same element as %h{~key}';

is try-eval('my %h; my ~key = "a"; %h.~key = "hi"; %h{~key}'), 'hi',
    '%h.~key = "hi" assigns the same as %h{~key} = "hi"';

is try-eval('my %h; my ~key = "a"; %h{~key} = "v"; %h.~key eq %h{~key}'), True,
    '%h.~key and %h{~key} give the identical value';

# --- .#expr: sugar for [#expr] (positional access) ---

is try-eval('my @a = <a b c>; my #idx = 1; @a[#idx] = "X"; @a.#idx'), 'X',
    '@a.#idx reads the same element as @a[#idx]';

is try-eval('my @a = <a b c>; my #idx = 1; @a.#idx = "X"; @a[#idx]'), 'X',
    '@a.#idx = "X" assigns the same as @a[#idx] = "X"';

is try-eval('my @a = <a b c>; my #idx = 2; @a.#idx eq @a[#idx]'), True,
    '@a.#idx and @a[#idx] give the identical value';

# --- this sugar is ~/#-specific, not a generic "any sigil after dot"
# mechanism: a $-sigiled variable in the same position is not a subscript.
# In rak mode `.$key` is a compile error that suggests `->$key` (Raku's
# indirect method call) or `."$key"` (a subscript by the variable); see
# 015-indirect-call.rak ---

throws-like 'my %h = a => 1; my $key = "a"; %h.$key', X::Comp,
    message => /'->$key' .* '."$key"'/,
    '%h.$key is not a subscript: it is an error that suggests ->$key and ."$key"';

# --- chaining with the existing .[ ]/.{ } sugar and Phase 1's .digit sugar ---

is try-eval('my %h; my ~k = "x"; %h{~k} = [10, 20, 30]; my #i = 1; %h.~k.#i'), 20,
    '%h.~k.#i chains: hash-lookup by ~-sigiled key, then positional index by #-sigiled value';

# vim: expandtab shiftwidth=4
