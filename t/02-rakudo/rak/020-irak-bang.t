use Test;

# irak directives, recognised only when they are the whole line:
#   !n   re-runs the source of submission n (n is its prompt number)
#   !!n  sets $_ to the value of submission n
#
# The REPL needs a tty, so the session runs under script(1), without a line
# editor (Terminal::LineEditor waits for a cursor-position answer script(1)
# never gives). The lines are fed slowly, so each is read on its own.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 7;

my @lines = '1+41', ' !0 ', '"x"', '!!0', 'say $_', '!9', '!!9', '"!0"', 'exit';

my %env = %*ENV;
%env<RAKUDO_LINE_EDITOR>  = 'none';
%env<RAKUDO_RAK_FRONTEND> = 1;
%env<RAKU_RAK_MODE>       = 1;

my $feed = 'sleep 2; ' ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.5; " }).join;
my $cmd  = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
my $out  = run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g);

like   $out, /'[1] >  !0 ' \n '1+41' \n '42' \n '[2] >'/, '!n echoes and re-runs submission n';
like   $out, /'[3] > !!0' \n '[3] > say $_' \n '42' \n/,  '!!n sets $_ to the value of submission n';
like   $out, /'irak: no submission 9'/,                    '!n on an unknown submission';
like   $out, /'irak: no value for submission 9'/,          '!!n on an unknown submission';
like   $out, /'"!0"' \n '!0' \n/,                          'not a directive unless the whole line';
nok    $out.contains('SORRY'),                             'no compile errors';
unlike $out, /'[3] > !!0' \n <-[\[]>/,                     '!!n prints nothing';
