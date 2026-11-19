use Test;
use nqp;

# irak greets with its own banner, naming the rak repository and the HEAD it
# was built from. Without a line editor, it names the one irak wants,
# Terminal::LineEditor, instead of the plain REPL's generic advice.
# The plain REPL keeps the Rakudo banner.
#
# The REPL needs a tty, so each session runs under script(1).

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 7;

my sub has-module($name) {
    so $*REPO.resolve(CompUnit::DependencySpecification.new(:short-name($name)))
}
my $editor = <Readline Linenoise Terminal::LineEditor>.first(&has-module);

sub banner(:$irak = True) {
    my %env = %*ENV;
    %env<RAKUDO_NO_VERSION>:delete;
    # Terminal::LineEditor asks the tty for the cursor position and waits for
    # an answer that script(1) never gives: run without it when it's there.
    if $editor { %env<RAKUDO_LINE_EDITOR> = 'none' } else { %env<RAKUDO_LINE_EDITOR>:delete }
    if $irak {
        %env<RAKUDO_RAK_FRONTEND> = 1;
        %env<RAKU_RAK_MODE>       = 1;
    }
    else {
        %env<RAKUDO_RAK_FRONTEND>:delete;
        %env<RAKU_RAK_MODE>:delete;
    }
    my $proc = run $script, '-qec', "'{$*EXECUTABLE.absolute}'", '/dev/null',
      :in, :out, :err, :%env;
    $proc.in.close;
    my $out = $proc.out.slurp(:close).subst("\r", '', :g);
    $proc.err.slurp(:close);
    $out
}

my $config := nqp::gethllsym('default', 'SysConfig').rakudo-build-config;
my $where   = (nqp::atkey($config, 'rak-repo-url'), nqp::atkey($config, 'rak-head'))
                .grep(*.chars).join(' @ ');

my $out = banner;
ok $out.starts-with("Welcome to irak, the rak shell.\n"), 'irak banner comes first';
ok !$where || $out.contains("\n$where\n"),               'banner names the repository and HEAD';
nok $out.contains('Rakudo'),                              'no Rakudo banner in irak';
nok $out.contains('Linenoise'),                           'no generic line-editor advice in irak';
if $editor {
    skip "$editor is installed, so no line-editor note";
}
else {
    ok $out.contains("irak: no line editor") && $out.contains('Terminal::LineEditor'),
      'irak says to install Terminal::LineEditor';
}

$out = banner :!irak;
ok $out.starts-with('Welcome to Rakudo'), 'plain REPL keeps the Rakudo banner';
nok $out.contains('irak'),                'plain REPL does not mention irak';
