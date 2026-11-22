use Test;
use nqp;

# irak feedback (cognominal/rak#1): before running a submission, irak shows
# how it reads it. A first Enter inserts `my` before undeclared variables,
# wherever `my` can stand, and colors each word by what it denotes; a second
# Enter on the same text within a second evaluates it.
#
# irak-feedback and irak-enter need no terminal, so they are called directly.

plan 42;

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
is text('$b'),            'my $b',            'a variable alone';
is text('say $x; $x = 1'), 'say my $x; $x = 1', 'the first occurrence, wherever it is';
is spans('say $x; $x = 1'), 'say:routine my:keyword $x:variable $x:variable',
  'the inserted `my` is a keyword';
is text('$x + $y'),       'my $x + my $y',    'each variable';
is text('$x == 1'),       '$x == 1',          'no `my` where it does not compile';
is spans('$x == 1'),      '$x:undeclared',    'the variable is then colored undeclared';
is text('say "$x"'),      'say "$x"',         'nor in an interpolation';
is text('~name = "a"'),   'my ~name = "a"',   'a rak string variable';
is text('#n = 3; #n++'),  'my #n = 3; #n++',  'a rak integer variable';
is text('say ~s ~ #n'),   'say my ~s ~ my #n', 'rak sigils anywhere';
is text('$*FOO = 1'),     '$*FOO = 1',        'a twigil variable is never declared';
is text('say $?'),        'say $?',           'nor $?';
is $repl.irak-feedback('$x = 1', :!declare)<text>, '$x = 1', ':!declare only colors';
ok $repl.irak-feedback('$x = 1', :!declare)<parsed>, 'the text then parses with the variable hidden';
nok $repl.irak-feedback('say if')<parsed>, 'a parse failure is reported';

# colors
is spans('say hello'),    'say:routine hello:naked-string', 'a naked string';
is spans('say foo, bar'), 'say:routine foo:naked-string bar:naked-string', 'the operands of a comma';
is spans('say foo bar'),  'say:routine foo:naked-string bar:naked-string', 'juxtaposed words';
is spans('sub hello {}; say hello'), 'sub:keyword say:routine hello:routine',
  'a declared sub is a routine';
is spans('ls -l'),        'ls:command',      'a command';
is spans('my $x; say $x, @*ARGS'), 'my:keyword $x:variable say:routine $x:variable @*ARGS:variable',
  'variables';
is spans('my ~s; say ~s'), 'my:keyword ~s:variable say:routine ~s:variable', 'rak sigil variables';
is spans('ls /etc ./a b/c ~ data.txt'), 'ls:command /etc:path ./a:path b/c:path ~:path',
  'paths in arguments, not data.txt';
is spans('ls >out 2>"e r" <in'), 'ls:command out:path "e r":path in:path',
  'redirection targets are paths';
is spans('my $f; say 1 >$f'), 'my:keyword $f:variable say:routine $f:variable',
  'a variable target is a variable';
is spans('$x == 1'), '$x:undeclared', 'undeclared, not variable';
is spans('say ~(pwd)'), 'say:routine pwd:command', 'a contextualizer is not a variable';
is spans('say if'),       'if:keyword',      'a keyword, though the parse fails';
is spans('if 0 { } else { }'), 'if:keyword else:keyword', 'keywords inside a statement';
is spans('sub f($x, #y) { 1 }'), 'sub:keyword', 'two parameters (a cycle in the Match)';

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
    is words($fb), 'my:keyword $m:variable', 'spans are offsets in that line';
    is-deeply $repl.irak-enter('!3', :now(50)), True, 'a !n directive finishes';
}

subtest 'the line editor hooks' => {
    plan 5;
    $repl.irak-enter('', :now(60));
    my &on-finish = $repl.irak-on-finish;
    is on-finish('$k = 1'), 'my $k = 1', 'a first Enter gives the new buffer';
    is $repl.irak-colors<text>, 'my $k = 1', 'whose colors the input field reads';
    is words($repl.irak-colors), 'my:keyword $k:variable', 'with their spans';
    is-deeply on-finish('my $k = 1'), True, 'a second Enter finishes';
    nok $repl.irak-colors, 'and drops the colors';
}

# vim: expandtab shiftwidth=4
