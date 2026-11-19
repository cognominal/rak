use Test;

plan 2;

# Outside rak mode `.$var` / `.&f` stay Raku's indirect method call.

my $m = -> %x { %x.elems };
my %h = a => 1, b => 2;
is %h.$m, 2, '.$var is an indirect method call';
my &f = -> $x { $x + 1 };
is 5.&f, 6, '.&f is an indirect method call';
