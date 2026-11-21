use Test;
use nqp;

# irak feedback (cognominal/rak#1): before running a submission, irak shows
# how it reads it. A first Enter inserts `my` before undeclared variables
# that can be declared and colors each word by what it denotes; a second
# Enter on the same text within a second evaluates it.
#
# irak-feedback and irak-enter need no terminal, so they are called directly.

plan 24;

%*ENV<RAKUDO_LINE_EDITOR> = 'none';   # keep the history file alone
my $repl = REPL.new(nqp::getcomp('Raku'), {}, True);

# "word:class" for each span of the feedback
sub words(%feedback) {
    %feedback<spans>.map({
        %feedback<text>.substr($_<from>, $_<to> - $_<from>) ~ ':' ~ $_<class>
    }).join(' ')
}
sub text($submission)  { $repl.irak-feedback($submission)<text> }
sub spans($submission) { words($repl.irak-feedback($submission)) }

# `my` insertion
is text('$x = 1'),        'my $x = 1',        'an assigned undeclared variable is declared';
is text('$x = 1; $x++'),  'my $x = 1; $x++', 'only its first occurrence';
is text('@a = 1, 2; %h := {}'), 'my @a = 1, 2; my %h := {}', 'one round per variable, = and :=';
is text('my $city = 1; say $ctiy'), 'my $city = 1; say $ctiy', 'no `my` for a likely typo';
like spans('my $city = 1; say $ctiy'), / '$ctiy:undeclared' /, 'the typo is colored undeclared';
is text('say $x; $x = 1'), 'say $x; $x = 1', 'no `my` when first used elsewhere';
is spans('say $x; $x = 1'), 'say:routine $x:undeclared $x:undeclared',
  'every occurrence is colored undeclared';
is text('@a.push: 3'),    '@a.push: 3',       'no `my` outside a declaration place';
is text('$x == 1'),       '$x == 1',          'a comparison is not an assignment';
is text('"$x"'),          '"$x"',             'nor an interpolation';
is text('$*FOO = 1'),     '$*FOO = 1',        'a twigil variable is never declared';
is text('say $?'),        'say $?',           'nor $?';

# colors
is spans('say hello'),    'say:routine hello:naked-string', 'a naked string';
is spans('sub hello {}; say hello'), 'sub:keyword say:routine hello:routine',
  'a declared sub is a routine';
is spans('ls -l'),        'ls:command',      'a command';
is spans('say if'),       'if:keyword',      'a keyword, though the parse fails';
is spans('if 0 { } else { }'), 'if:keyword else:keyword', 'keywords inside a statement';

# compile-time code runs, silently
is text('BEGIN say "noise"; $y := 2'), 'BEGIN say "noise"; my $y := 2',
  'BEGIN code does not stop the analysis';
my $proc = run $*EXECUTABLE, '-e', q:to/END/, :out, :err;
    use nqp;
    %*ENV<RAKUDO_LINE_EDITOR> = 'none';
    REPL.new(nqp::getcomp('Raku'), {}, True)
      .irak-feedback('BEGIN { say "noise"; note "noise" }; 42; $y := 2');
    END
is $proc.out.slurp(:close) ~ $proc.err.slurp(:close), '',
  'neither BEGIN output nor worries leak';

# Enter, with an injected clock
ok $repl.irak-feedback('if 1 {')<incomplete>, 'an incomplete submission is flagged';
is-deeply $repl.irak-enter('if 1 {', :now(0)), True, 'an incomplete submission finishes at once';

subtest 'the second Enter' => {
    plan 6;
    my $first = $repl.irak-enter('$n = 1', :now(10));
    is $first<text>, 'my $n = 1', 'the first Enter rewrites';
    is-deeply $repl.irak-enter('my $n = 1', :now(10.5)), True, 'the same text within a second finishes';
    isa-ok $repl.irak-enter('my $n = 1', :now(20)), Map, 'a new first Enter after that';
    isa-ok $repl.irak-enter('my $n = 1', :now(21.5)), Map, 'more than a second analyzes again';
    isa-ok $repl.irak-enter('my $n = 2', :now(21.7)), Map, 'an edit analyzes again';
    is-deeply $repl.irak-enter('', :now(30)), True, 'empty input finishes';
}

subtest 'a continuation line' => {
    plan 3;
    my $fb = $repl.irak-enter('$m = 1 }', :before("if 1 \{\n"), :now(40));
    is $fb<text>, 'my $m = 1 }', 'only the line being edited is rewritten';
    is words($fb), 'my:keyword', 'spans are offsets in that line';
    is-deeply $repl.irak-enter('!3', :now(50)), True, 'a !n directive finishes';
}

subtest 'the line editor hooks' => {
    plan 5;
    $repl.irak-enter('', :now(60));
    my &on-finish = $repl.irak-on-finish;
    is on-finish('$k = 1'), 'my $k = 1', 'a first Enter gives the new buffer';
    is $repl.irak-colors<text>, 'my $k = 1', 'whose colors the input field reads';
    is words($repl.irak-colors), 'my:keyword', 'with their spans';
    is-deeply on-finish('my $k = 1'), True, 'a second Enter finishes';
    nok $repl.irak-colors, 'and drops the colors';
}

# vim: expandtab shiftwidth=4
