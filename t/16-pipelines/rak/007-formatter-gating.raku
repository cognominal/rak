use Test;

plan 1;

# Plain Raku: a lone `.` is still a syntax error.

throws-like { EVAL q{$_ = 1; .} }, X::Syntax::Malformed, 'a lone . is an error in .raku';
