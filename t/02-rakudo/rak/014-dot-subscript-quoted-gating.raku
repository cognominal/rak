use Test;

plan 3;

# Outside rak mode `."name"` without arguments stays Raku's error and
# `."name"(…)` a method call: the quoted dotty subscript must not leak
# into Raku.

throws-like { EVAL q[my %h = a => 1; %h."a"] }, X::Comp,
    message => /'Quoted method name requires parenthesized arguments'/,
    q[%h."a" is still an error];
throws-like { EVAL q[my %h = a => 1; %h.'a'] }, X::Comp,
    q[%h.'a' is still an error];
is 42."Str"(), '42', q[."name"() is a method call];
