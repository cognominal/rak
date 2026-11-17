use Test;

plan 4;

# Outside rak mode a leading `.name` stays a method call on $_ and `.5`
# stays a number: the leading dotty subscript must not leak into Raku.

given { a => 1 } {
    is .elems, 1, 'leading .name is a method call';
    dies-ok { .a }, 'leading .name is not a hash subscript';
}
is .5, 1/2, 'leading .5 is a number';
dies-ok { EVAL 'given 1 { ->chars }' }, 'leading ->name is not a method call';
