use Test;

# irak records each finished submission in atuin's history when `atuin` is on
# PATH (rak-plans/features/atuin.md). A fake `atuin` logs its calls here.
#
# The REPL needs a tty, so each session runs under script(1), without a line
# editor, as 029 does.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 11;

my $root = $*TMPDIR.add("irak-atuin-$*PID");
my $bin  = $root.add('bin');
my $log  = $root.add('log');
$bin.mkdir;
$bin.add('atuin').spurt: qq:to/SH/;
    #!/bin/sh
    case "\$1" in
      uuid) echo fake-session ;;
      history)
        printf '%s|' "\$@" >> '$log'
        printf 'shell=%s session=%s\\n' "\$ATUIN_SHELL" "\$ATUIN_SESSION" >> '$log'
        [ "\$2" = start ] && echo "id\$\$"
        ;;
    esac
    SH
$bin.add('atuin').chmod(0o755);

sub session(*@lines, :%extra) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAKUDO_NO_VERSION>   = 1;
    %env<XDG_CONFIG_HOME>     = $root.add('config').absolute;
    %env<XDG_STATE_HOME>      = $root.add('state').absolute;
    %env<PATH>                = $bin.absolute ~ ':' ~ %*ENV<PATH>;
    %env{.key} = .value for %extra;
    $log.unlink;
    my $feed = 'sleep 2; ' ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.5; " }).join;
    my $cmd  = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
    run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close);
    $log.e ?? $log.slurp !! ''
}

{
    my $log = session('1 + 1', 'false', '- 2', '-', '!!0', 'sub f {', '}', 'exit');
    like $log, /^^ 'history|start|--hook|--|1 + 1|'/, 'a submission is recorded';
    like $log, /'shell=irak session=fake-session'/,   'with irak as the shell, in one session';
    like $log, /^^ 'history|end|--hook|--exit|0|--duration|' \d+ '|--|id'/,
                                                       'its end has the status and a duration';
    like $log, /^^ 'history|start|--hook|--|false|' .*? \n
                ^^ 'history|end|--hook|--exit|1|'/,    "a failed command's status is recorded";
    like $log, /^^ 'history|start|--hook|--|- 2|'/,    'the topic prefix is kept';
    like $log, /^^ 'history|start|--hook|--|sub f {' \n '}|'/,
                                                       'a multi-line submission is one entry';
    nok  $log ~~ /'--|-|'/,                            'a lone `-` is not recorded';
    nok  $log ~~ /'--|!!0|'/,                          '`!!0` is not recorded';
    is   +$log.lines.grep(/^^ 'history|start'/), 4,    'one start per submission';
    is   +$log.lines.grep(/^^ 'history|end'/),   4,    'one end per start';
}

{
    my $log = session('1 + 1', 'exit', :extra(RAKUDO_DISABLE_ATUIN => 1));
    is $log, '', 'RAKUDO_DISABLE_ATUIN turns recording off';
}

run 'rm', '-rf', $root;
