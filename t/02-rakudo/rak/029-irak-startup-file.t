use Test;

# The irak prompt makes rak's XDG folders and runs the startup file,
# $XDG_CONFIG_HOME/rak/init.rak, before the first submission
# (rak-plans/features/startup-file.md, docs/adr/0006).
#
# The REPL needs a tty, so each session runs under script(1), without a line
# editor (Terminal::LineEditor waits for a cursor-position answer script(1)
# never gives). The lines are fed slowly, so each is read on its own.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 16;

my $root = $*TMPDIR.add("irak-startup-$*PID");
my $n    = 0;

# A fresh pair of XDG folders, with $init as the startup file when given.
sub xdg(Str $init?) {
    my $dir = $root.add(++$n);
    my %xdg = config => $dir.add('config'), state => $dir.add('state');
    with $init {
        %xdg<config>.add('rak').mkdir;
        %xdg<config>.add('rak/init.rak').spurt: $init;
    }
    %xdg
}

sub env(%xdg) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAKUDO_NO_VERSION>   = 1;
    %env<XDG_CONFIG_HOME>     = %xdg<config>.absolute;
    %env<XDG_STATE_HOME>      = %xdg<state>.absolute;
    %env
}

sub session(%xdg, *@lines, :$args = '') {
    my $feed = 'sleep 2; ' ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.5; " }).join;
    my $cmd  = "($feed) | '$script' -qec \"'{$*EXECUTABLE.absolute}' $args\" /dev/null";
    run(<sh -c>, $cmd, :out, :err, :env(env(%xdg))).out.slurp(:close).subst("\r", '', :g)
}

{
    my %xdg = xdg(q:to/RAK/);
        say "init ran";
        sub greet { "hi" }
        my $answer = 42;
        "last value"
        RAK
    my $out = session(%xdg, 'say $_ === Any', 'greet()', '$answer', '!0', 'exit');
    like $out, /'init ran' \n '[0] >'/,            'the startup file runs before the first prompt';
    like $out, /'[0] > say $_ === Any' \n 'True'/, 'it leaves $_ alone and takes no number';
    like $out, /'greet()' \n 'hi'/,                'its routines are seen by submissions';
    like $out, /'$answer' \n '42'/,                'so are its variables';
    like $out, /'!0' \n 'greet()' \n 'hi'/,        '!n counts submissions only';
    ok %xdg<state>.add('rak').d,                   'the state folder is made';

    $out = session(%xdg, 'greet()', 'exit', :args<--no-init>);
    nok $out.contains('init ran'),                 '--no-init skips the startup file';
    like $out, /'Undeclared routine'/,             '... and what it defines';
}

{
    my %xdg = xdg();
    my $out = session(%xdg, '1+1', 'exit');
    like $out, /'[0] > 1+1' \n '2'/,               'no startup file: irak starts';
    ok %xdg<config>.add('rak').d && %xdg<state>.add('rak').d,
      'the config and state folders are made when missing';
}

{
    my %xdg  = xdg("sub early \{ 7 }\nmy \$x = ;\n");
    my $file = %xdg<config>.add('rak/init.rak').absolute;
    my $out  = session(%xdg, '1+1', 'exit');
    ok $out.contains("at $file:2"),                'a compile error names the file and line';
    like $out, /'[0] > 1+1' \n '2'/,               '... and irak starts anyway';
}

{
    my %xdg = xdg("sub early \{ 7 }\ndie 'boom';\nsub late \{ 8 }\n");
    my $out = session(%xdg, 'early()', 'exit');
    like $out, /'boom' \n .*? 'init.rak line 2'/,  'a runtime error is shown with its line';
    like $out, /'early()' \n '7'/,                 '... and what ran before it is kept';
}

# History: $XDG_STATE_HOME/rak/history, whatever RAKUDO_HIST says.
{
    my %xdg = xdg();
    my %env = env(%xdg);
    %env<RAKUDO_HIST> = $root.add('rakudo-hist').absolute;
    my $hist = run($*EXECUTABLE, '-e',
      'use nqp; say REPL.new(nqp::getcomp("Raku"), {}, True)->history-file',
      :out, :err, :%env).out.slurp(:close).trim;
    is $hist, %xdg<state>.add('rak/history').absolute, 'irak ignores RAKUDO_HIST';
}

# An XDG folder that cannot be made costs one warning naming it.
{
    my $ro = $root.add('read-only');
    $ro.mkdir;
    $ro.chmod(0o555);
    my %env = env(%(config => $root.add('writable'), state => $ro));
    my @err = run($*EXECUTABLE, '-e',
      'use nqp; REPL.new(nqp::getcomp("Raku"), {}, True)->history-file',
      :out, :err, :%env).err.slurp(:close).lines;
    is-deeply @err, ["irak: cannot create {$ro.add('rak')}; history will not be saved"],
      'one warning for an unwritable state folder, naming it';
    $ro.chmod(0o755);
}

# Clean up without a recursive delete.
sub tidy(IO::Path $p) {
    if $p.d && !$p.l { tidy($_) for $p.dir; $p.rmdir }
    else             { $p.unlink }
}
tidy($root);
