use Test;

plan 4;

# Outside rak mode `~` and `#` are not sigils: `~.foo` and `~foo` stringify,
# and `#foo` starts a comment. Modules are compiled this way under the rak
# frontend too, so this is what lets them load in irak.

is (1, 2).map({ ~.succ }).join(','), '2,3', '~.name is prefix ~ on a method call on $_';
sub foo { 42 }
is ~foo, '42', '~name stringifies a call';
my $x = 1
  #word comment between an operand and its infix
  || 2;
is $x, 1, '#word is a comment';
is (await Promise.kept(42).then: { ~.result }), '42', '~.result inside a .then block';
