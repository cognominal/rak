use Test;

plan 1;

# Plain Raku has no aliases.

dies-ok { EVAL 'alias ll=ls -l; ll' }, 'alias is not a statement in .raku';
