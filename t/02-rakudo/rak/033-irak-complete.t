use Test;

# TAB in irak (rak-plans/features/completion.md): the selector under the
# cursor, the dotty chain that leads to its subject, the candidates, the
# YAML previews, and a session where a fake `fzf` makes the choice.

plan 43;

my $e = REPL::Completions::Engine.new;

# The site of a line with the cursor at `█`
sub site(Str:D $marked) {
    my $pos  = $marked.index('█');
    my $line = $marked.subst('█', '');
    $e.selector-site($line, $pos) // $e.method-site($line, $pos)
}

# The selector site
{
    my $s = site('.k█');
    is-deeply ($s<from to prefix kind root>), (1, 2, 'k', 'key', ''), 'a leading `.k`: a key of the topic';
    is-deeply $s<steps>, (), '… with no steps before it';

    $s = site('%h.a.1.k█');
    is $s<root>, '%h', 'a chain starts from its variable';
    is-deeply $s<steps>, (key => 'a', index => 1), '… and walks its selectors';

    $s = site('%h.k█ey9.foo');
    is-deeply ($s<from>, $s<to>), (3, 7), 'the selector right of the cursor is replaced, not the chain';

    $s = site(q{.'foo b█ar'.z});
    is-deeply ($s<from to prefix kind>), (1, 10, 'foo b', 'key'), 'inside quotes, up to the closing quote';

    is-deeply site(q{say .a.'x y'.1.█})<steps>, (key => 'a', key => 'x y', index => 1),
      'quoted and numeric selectors in the chain';
    is site('$x.12█')<kind>, 'index', 'digits complete an index';
    is site('$x.█')<kind>,   'any',   'nothing typed: keys and indices';
    is site('$y = .k█')<root>, '', 'a leading `.` after `=` is the topic';
}

# Sites that get no completion
nok site('1.5█'),     'a number is not a chain';
nok site('foo().k█'), 'a call is never run to complete';
nok site('%h..k█'),   'a range is not a selector';
nok site('$x->m.k█'), 'a method in the chain is never run';

# The `->` method site
{
    my $s = site('@a->el█ems');
    is-deeply ($s<from to prefix root>), (4, 9, 'el', '@a'), '`->` completes a method name';
}

# Walking the chain
is $e.walk-selectors({ a => [1, { b => 2 }] }, (key => 'a', index => 1, key => 'b')), 2,
  'the chain leads to its value';
{
    my %h = a => 1;
    nok $e.walk-selectors(%h, (key => 'z', key => 'y')).defined, 'a missing key gives nothing';
    nok %h<z>:exists, '… and is not autovivified';
}
nok $e.walk-selectors((1..*), (index => 1,)).defined, 'a lazy list is not walked';

# Selector texts
is $e.selector-text('key-a1'),  'key-a1',      'an identifier needs no quotes';
is $e.selector-text('foo bar'), q{'foo bar'},  'a key with a space is quoted';
is $e.selector-text('12'),      q{'12'},       'a key of digits is quoted, as .12 is an index';
is $e.selector-text(q{don't go}), q{'don\'t go'}, 'a quote in a quoted key is escaped';

# Candidates
{
    my %t = :key1(1), :key2(2), :foo(3), 'foo bar' => [1, 2, 3];
    my $c = $e.selector-candidates(%t, 'k', 'key');
    is-deeply $c<items>.map(*<text>).List, <key1 key2>, 'keys that start with the prefix';
    is $c<items>[1]<value>, 2, '… with their values';
    is $c<header>, 'Hash · 4 keys', 'the header gives the type and size';
    is-deeply $e.selector-candidates(%t, '', 'any')<items>.map(*<text>).List,
      ('foo', q{'foo bar'}, 'key1', 'key2'), 'with nothing typed, all keys, quoted when needed';

    $c = $e.selector-candidates((^1000).Array, '12', 'index');
    is $c<items>.elems, 11, 'digits narrow the indices across the whole range';
    is $c<header>, 'Array · 0..999', 'an array shows its range';
    $c = $e.selector-candidates((^1000).Array, '', 'any');
    is $c<items>.elems, 200, 'at most 200 candidates';
    is $c<header>, 'Array · 0..999 · showing 200', '… and the header says so';

    $c = $e.selector-candidates('ab' ~~ /(.) $<n>=(.)/, '', 'any');
    is-deeply $c<items>.map(*<text>).List, ('n', '0'), 'a Match offers its keys and its indices';
    nok $e.selector-candidates(42, '', 'any'), 'a number has no selectors';
    ok $e.method-candidates([1, 2], 'ele')<items>.first(*<text> eq 'elems')<preview>
      .contains('List'), '`->` candidates preview their signatures';
}

# The YAML preview
is REPL::DataInspector.new.preview(
  { a => [1, { b => 3 }], c => 'x y', d => 'true', e => {}, f => (1..*), g => Any,
    h => "two\nlines" }, :max-depth(2)),
  qq:to/YAML/, 'the preview is block YAML, cut at its depth';
    a:
      - 1
      - \{… 1 key}
    c: x y
    d: "true"
    e: \{}
    f: <lazy>
    g: null
    h: "two\\nlines"
    YAML

# A session: TAB opens a fake fzf, which logs its arguments and the preview
# of the second candidate, and chooses the candidate named in FAKE_FZF_PICK.
my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
my $editor = so $*REPO.resolve(CompUnit::DependencySpecification.new(:short-name<Terminal::LineEditor>));
my $fzf    = run(<sh -c>, 'command -v fzf', :out, :err).out.slurp(:close).trim;

my $root = $*TMPDIR.add("irak-complete-$*PID");
my $bin  = $root.add('bin');
my $log  = $root.add('log');
$bin.mkdir;
$bin.add('fzf').spurt: qq:to/SH/;
    #!/bin/sh
    input=\$(cat)
    for a in "\$@"; do
      printf 'arg %s\\n' "\$a" >> '$log'
      case "\$a" in
        --preview=*) sh -c "\$(printf '%s' "\$\{a#--preview=}" | sed 's/\{1}/1/')" >> '$log' ;;
      esac
    done
    printf '%s\\n' "\$input" | awk -F'\\t' -v p="\$FAKE_FZF_PICK" '\$2 == p'
    echo FAKE-FZF-DONE >&2
    SH
$bin.add('fzf').chmod(0o755);

sub plain(Str:D $s) { $s.subst("\r\n", "\n", :g).subst("\r", "", :g) }

# Did a submission print $v? Its output follows a newline or an OSC 133 mark.
sub printed(Str:D $out, $v) { so $out ~~ / <[\n\\]> $v \n / }

# Runs irak under script(1). Each prompt asks the editor's two cursor
# queries; the answer to the second is followed by the next of @typed. A
# TAB that runs fzf waits for it before Enter.
sub session(@typed, Str:D $pick, :&until!) {
    my %env = %*ENV;
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAKUDO_NO_VERSION>   = 1;
    %env<RAKUDO_LINE_EDITOR>  = 'LineEditor';
    %env<RAKUDO_DISABLE_ATUIN> = 1;
    %env<RAK_PAGER>           = 'cat';
    %env<FAKE_FZF_PICK>       = $pick;
    %env<XDG_CONFIG_HOME>     = $root.add('config').absolute;
    %env<XDG_STATE_HOME>      = $root.add('state').absolute;
    %env<PATH>                = $bin.absolute ~ ':' ~ %*ENV<PATH>;
    $log.unlink;

    my $proc = Proc::Async.new(:w, $script, '-qec', "'{$*EXECUTABLE.absolute}'", '/dev/null');
    my $out  = '';
    my $seen = 0;
    my $fzfs = 0;
    my $met  = Promise.new;
    $proc.stdout(:bin).tap: -> $chunk {
        $out ~= $chunk.decode('latin-1');
        while $seen < +$out.indices("\e[6n") {
            ++$seen;
            if $seen %% 2 {
                my $next = @typed[$seen div 2 - 1] // '';
                $proc.print("\e[24;80R" ~ $next.subst("\r", ''));
                Promise.in(1).then({ $proc.print("\r\r") }) if $next.ends-with("\r");
            }
            else { $proc.print("\e[1;6R") }
        }
        while $fzfs < +$out.indices('FAKE-FZF-DONE') {
            ++$fzfs;
            Promise.in(1).then({ $proc.print("\r\r") });
        }
        $met.keep if $met.status ~~ Planned && until(plain($out));
    }
    $proc.stderr(:bin).tap: -> $ { };
    my $done = $proc.start(:ENV(%env));
    await Promise.anyof($done, $met, Promise.in(30));
    $proc.kill(SIGKILL) unless $done;
    await Promise.anyof($done, Promise.in(5));
    plain($out)
}

my $topic = '{ :key1(1), :key2(2), :foo(3) }' ~ "\r";

SKIP: {
    skip 'script(1) and Terminal::LineEditor are needed for a session', 7
      unless $script && $editor;

    my $out = session([$topic, ".k\t"], 'key2', :until(*.&printed(2)));
    ok printed($out, 2), '`.k` TAB: fzf chooses key2, and the line runs as `.key2`';
    ok $out ~~ / "\e[6 q" .*? '.k' .*? "\e[0 q" .*? FAKE\-FZF\-DONE /,
      'the cursor is a bar while editing, and the default while fzf runs';
    my $args = $log.e ?? $log.slurp !! '';
    ok $args.contains("arg --query=k\n"), 'fzf gets the typed prefix as its query';
    ok $args.contains("arg --header=Hash · 3 keys\n"), '… the header';
    ok $args.lines.grep('2'), '… and a preview of each value';

    $out = session([$topic, ".f\t\r"], '', :until(*.&printed(3)));
    ok printed($out, 3) && !$log.e, 'one candidate is inserted without fzf';

    $out = session([$topic, ".kXYZ\e[D\e[D\e[D\t"], 'key1', :until(*.&printed(1)));
    ok printed($out, 1), 'the rest of the selector right of the cursor is replaced';
}

# The real fzf, without its interface
REAL: {
    skip 'fzf is not installed', 1 unless $fzf;
    my $p = run $fzf, '--filter=ky2', "--delimiter=\t", '--with-nth=2..', :in, :out;
    $p.in.spurt: "0\tkey1\n1\tkey2\n", :close;
    is $p.out.slurp(:close), "1\tkey2\n", 'fzf filters on the label and returns the index';
}

run 'rm', '-rf', $root;
