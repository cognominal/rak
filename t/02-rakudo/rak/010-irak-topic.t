use Test;

# irak topic: at the start of an irak submission, $_ holds the value of the
# previous submission. A submission that fails, returns Nil or prints output
# leaves $_ unchanged. The plain Raku REPL keeps its usual $_.
#
# The REPL needs a tty, so each session runs under script(1).

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 9;

sub session(@submissions, :$irak = True) {
    my %env = %*ENV;
    if $irak {
        %env<RAKUDO_RAK_FRONTEND> = 1;
        %env<RAKU_RAK_MODE>       = 1;
    }
    else {
        %env<RAKUDO_RAK_FRONTEND>:delete;
        %env<RAKU_RAK_MODE>:delete;
        %env<RAKUDO_RAKUAST> = 1;
    }
    %env<RAKUDO_LINE_EDITOR> = 'none';
    my $cmd  = "'{$*EXECUTABLE.absolute}'";
    my $proc = run $script, '-qec', $cmd, '/dev/null', :in, :out, :err, :%env;
    $proc.in.spurt: @submissions.join("\n") ~ "\n", :close;
    my $out = $proc.out.slurp(:close).subst("\r", '', :g);
    $proc.err.slurp(:close);
    # The value of submission N follows the prompt "[N] > ". The number only
    # advances once a value is shown, so the last line for N is its value.
    my %value;
    for $out.lines -> $line {
        %value{+$0} = ~$1 if $line ~~ / ^ '[' (\d+) '] > ' (.*) $ /;
    }
    %value
}

my %v = session [
    '{a => 1, b => [5, 6]}',   # [0]
    '.b',                      # [1] $_<b>
    '.1',                      # [2] $_[1]
    'say "out"',               # prints: $_ stays 6
    'Nil',                     # [3] Nil: $_ stays 6
    'die "boom"',              # fails: $_ stays 6
    '$_ + 100',                # [4]
    '->succ',                  # [5] method on $_
];
is %v<1>, '[5 6]', 'leading .b subscripts the previous value';
is %v<2>, '6',     'leading .1 subscripts the previous value';
is %v<4>, '106',   'printing, Nil and a failure leave $_ unchanged';
is %v<5>, '107',   'leading ->succ calls the method on the previous value';

%v = session ['42', '$_ * 2', '$_ * 2'];
is %v<1>, '84',  '$_ is the value of the previous submission';
is %v<2>, '168', '$_ follows each submission';

%v = session ['my $x = 5', '$_'];
is %v<1>, '5', 'a declaration submission sets $_ to its value';

%v = session ['42', '$_'], :!irak;
is %v<0>, '42',    'plain REPL shows the value';
is %v<1>, '(Any)', 'plain REPL does not set $_';
