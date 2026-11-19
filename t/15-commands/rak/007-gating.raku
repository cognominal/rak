use Test;

plan 2;

# Plain Raku: a lone word is not a command, and `$?` is not the exit status.

my $f = "rak-cmd-gating-$*PID";
try { EVAL "touch $f" }
nok $f.IO.e, 'a lone command does not run in .raku';
$f.IO.unlink if $f.IO.e;
dies-ok { EVAL 'say $?' }, '$? is not a variable in .raku';
