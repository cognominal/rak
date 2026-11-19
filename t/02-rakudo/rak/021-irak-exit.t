use Test;

# irak shows a non-zero exit status dimmed; a command's Proc prints nothing
# and leaves $_ unchanged. Runs under script(1) for a tty, as 020 does.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 4;

my @lines = '"x"', 'false', 'true', 'say $_', 'exit';

my %env = %*ENV;
%env<RAKUDO_LINE_EDITOR>  = 'none';
%env<RAKUDO_RAK_FRONTEND> = 1;
%env<RAKU_RAK_MODE>       = 1;

my $feed = 'sleep 2; ' ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.5; " }).join;
my $cmd  = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
my $out  = run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g);

like   $out, /'> false' \n "\e[2mexit 1\e[0m" \n/, 'non-zero exit shown dimmed';
like   $out, /'> true' \n '[' /,                   'zero exit shows nothing';
like   $out, /'> say $_' \n 'x' \n/,               '$_ unchanged by commands';
nok    $out.contains('RakProc'),                   'no Proc printed';
