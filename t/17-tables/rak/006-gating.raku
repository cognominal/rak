use Test;

plan 2;

# Tables are rak mode only: plain Raku has no `ls` builtin, and `get` is
# still the routine that reads a line.

throws-like 'ls', X::Undeclared::Symbols, 'ls is no builtin in .raku';
is EVAL('my $_ = 1; ?&get'), True, 'get is the core routine';
