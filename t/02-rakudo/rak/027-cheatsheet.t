use Test;

# The terminal cheat sheet (rak-plans/highlight.md): rak-docs/CHEATSHEET.ans is
# generated from rak-docs/CHEATSHEET.md by tools/rak-cheatsheet.raku, with
# its rak code highlighted as irak highlights it.

plan 5;

my $md  = 'rak-docs/CHEATSHEET.md';
my $ans = 'rak-docs/CHEATSHEET.ans';

my $proc = run $*EXECUTABLE, 'tools/rak-cheatsheet.raku', $md, :out, :err,
  :env(%*ENV, RAKUDO_LINE_EDITOR => 'none');
my $out = $proc.out.slurp(:close);
is $proc.err.slurp(:close), '', 'the generator runs without a word on stderr';

ok $out.contains("\e[36muc\e[0m \e[33mhello\e[0m"), 'a block is highlighted';
ok $out.contains("\e[2m# 6\e[0m"), 'its comments are dim';
ok $out.contains("\e[1;32mcd\e[0m dir"), 'a phrase in a table is highlighted';

is $out, $ans.IO.slurp, "$ans is up to date (make rak-cheatsheet)";

# vim: expandtab shiftwidth=4
