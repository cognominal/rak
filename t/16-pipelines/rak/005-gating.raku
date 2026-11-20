use Test;

plan 2;

# Plain Raku: a spaced | is the any junction, and @? is not a variable.

my $j = EVAL q{$_ = <a b>; .[0] | 'c'};
isa-ok $j, Junction, '.[0] | "c" is a junction in .raku';
dies-ok { EVAL 'say @?' }, '@? is not a variable in .raku';
