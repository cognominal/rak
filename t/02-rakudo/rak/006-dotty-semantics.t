use Test;

# The dotty-sugar spellings of SUBSCRIPT-OPERATOR.md, all in one `.rak` file:
# `.identifier` and `.digits` are subscripts, `->identifier` is the
# parameterless method call, and `.identifier()` stays a real method call.
# (This was `t/test-dotty-semantics.rak`, a `say` demo with no assertions.)
#
# It is a subprocess fixture test rather than an `EVAL` one because the
# behavior under test is keyed off the *file extension* of the compilation
# unit, which `EVAL` has no notion of — same reason as
# `005-dot-subscript-name.t`.

plan 2;

my $tmp-dir = $*TMPDIR.add("dotty-semantics-test-{$*PID}");
mkdir $tmp-dir;
END { rmdir $tmp-dir if $tmp-dir.e }

my $source = q:to/RAK/;
my %h = a => 1, b => 2, c => 3;
say %h.a;
say %h.b;
my @a = 10, 20, 30;
say @a.1;
say @a.2;
say elems(%h->keys);
say elems(%h.keys());
RAK

my $path = $tmp-dir.add('dotty.rak');
spurt $path, $source;
LEAVE { unlink $path }

my %env = %*ENV;
%env<RAKUDO_RAKUAST> = 1;

my $proc = run $*EXECUTABLE.absolute, $path.absolute, :env(%env), :out, :err;
my $out  = $proc.out.slurp(:close);
my $err  = $proc.err.slurp(:close);

is $proc.exitcode, 0, 'the .rak fixture runs' or diag $err;
is-deeply $out.lines, ('1', '2', '20', '30', '3', '3'),
    '.name and .digits are subscripts, ->name and .name() are method calls';
