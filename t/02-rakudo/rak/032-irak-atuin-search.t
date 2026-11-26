use Test;

# In irak, Ctrl-R runs `atuin search --interactive` with the buffer as its
# query, and the buffer gets the entry that the search chose
# (rak-plans/features/atuin.md). A fake `atuin` reads its choice from the
# terminal, so the test also checks that the search gets every key typed.
#
# The REPL needs a tty, so each session runs under script(1), with
# Terminal::LineEditor, as 028 does. The test answers the editor's two
# cursor-position queries before typing.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

sub has-module($name) {
    so $*REPO.resolve(CompUnit::DependencySpecification.new(:short-name($name)))
}
plan :skip-all('Terminal::LineEditor is needed for Ctrl-R')
  unless has-module('Terminal::LineEditor');

plan 5;

my $root = $*TMPDIR.add("irak-atuin-search-$*PID");
my $bin  = $root.add('bin');
my $log  = $root.add('log');
$bin.mkdir;
# `search` logs its query, says it is ready, reads a line, and writes the
# line to stderr as its choice, with atuin's prefix for Enter.
$bin.add('atuin').spurt: qq:to/SH/;
    #!/bin/sh
    case "\$1" in
      uuid) echo fake-session ;;
      search)
        printf 'query=%s shell=%s\\n' "\$ATUIN_QUERY" "\$ATUIN_SHELL" >> '$log'
        echo FAKE-SEARCH-READY
        IFS= read -r choice
        [ -n "\$choice" ] && printf '__atuin_accept__:%s\\n' "\$choice" >&2
        echo FAKE-SEARCH-DONE
        ;;
    esac
    SH
$bin.add('atuin').chmod(0o755);

# The terminal output with line ends as "\n"
sub plain(Str:D $s) { $s.subst("\r\n", "\n", :g).subst("\r", "", :g) }

# Runs irak under script(1), types $typed and Ctrl-R, answers the search
# with $choice, then types Enter twice. Returns what the terminal got once
# &until holds for it, or after 30 seconds.
sub session(Str:D $typed, Str:D $choice, :&until!) {
    my %env = %*ENV;
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAKUDO_NO_VERSION>   = 1;
    %env<RAKUDO_LINE_EDITOR>  = 'LineEditor';
    %env<RAK_PAGER>           = 'cat';
    %env<XDG_CONFIG_HOME>     = $root.add('config').absolute;
    %env<XDG_STATE_HOME>      = $root.add('state').absolute;
    %env<PATH>                = $bin.absolute ~ ':' ~ %*ENV<PATH>;
    %env<RAKUDO_DISABLE_ATUIN>:delete;
    $log.unlink;

    my $proc = Proc::Async.new(:w, $script, '-qec', "'{$*EXECUTABLE.absolute}'", '/dev/null');
    my $out  = '';
    my $seen = 0;
    my $step = 0;
    my $met  = Promise.new;
    $proc.stdout(:bin).tap: -> $chunk {
        $out ~= $chunk.decode('latin-1');
        while $seen < +$out.indices("\e[6n") {
            ++$seen;
            if $seen == 1 { $proc.print("\e[1;6R") }
            elsif $seen == 2 { $proc.print("\e[24;80R$typed\x12") }
        }
        if $step == 0 && $out.contains('FAKE-SEARCH-READY') {
            $step = 1;
            $proc.print("$choice\r");
        }
        elsif $step == 1 && $out.contains('FAKE-SEARCH-DONE') {
            $step = 2;
            # Enter once the editor is back in raw mode
            Promise.in(1).then({ $proc.print("\r\r") });
        }
        $met.keep if $step == 2 && $met.status ~~ Planned && until(plain($out));
    }
    $proc.stderr(:bin).tap: -> $ { };
    my $done = $proc.start(:ENV(%env));
    await Promise.anyof($done, $met, Promise.in(30));
    $proc.kill(SIGKILL) unless $done;
    await Promise.anyof($done, Promise.in(5));
    plain($out)
}

{
    my $out = session('6 *', '6 * 7', :until(*.contains("42\n")));
    is $log.slurp, "query=6 * shell=irak\n", 'the search gets the buffer as its query';
    ok $out.contains("42\n"), 'Enter runs the chosen entry';
}

{
    my $out = session('say 3', '', :until(*.contains("3\n\e]133;D")));
    ok $log.e,                       'the search runs when nothing is chosen';
    ok $out.contains("3\n\e]133;D"), 'the buffer keeps the query';
    nok $out.contains('__atuin_accept__'), "atuin's prefix never shows";
}

run 'rm', '-rf', $root;
