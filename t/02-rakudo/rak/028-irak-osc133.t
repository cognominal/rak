use Test;

# irak emits OSC 133 semantic prompt marks: A before the prompt, B after it,
# C before a submission's output, D;<status> after it. A multi-line submission
# is one command. Only with Terminal::LineEditor on a tty, and not when
# RAKUDO_DISABLE_OSC133 is set.
#
# The REPL needs a tty, so each session runs under script(1). Terminal::
# LineEditor asks the terminal for the cursor position twice before each
# prompt (where the input field starts, then the terminal size); script(1)
# never answers, so the test answers for it before typing each line.
#
# Each session drives one prompt only. Terminal::LineEditor 0.0.23, even as
# rak patches it, leaves the thread that read the previous line blocked on
# standard input, and the next prompt waits for it, in cooked mode, until a
# newline comes. So the continuation case stops at the continuation prompt.
# The editor gets the prompt without its last character, hence `*` for `* `.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

sub has-module($name) {
    so $*REPO.resolve(CompUnit::DependencySpecification.new(:short-name($name)))
}
plan :skip-all('Terminal::LineEditor is needed for the marks')
  unless has-module('Terminal::LineEditor');

plan 17;

sub mark($m) { "\e]133;{$m}\e\\" }
my $A  = mark('A');
my $B  = mark('B');
my $C  = mark('C');
my $D0 = mark('D;0');
my $D1 = mark('D;1');
my $D3 = mark('D;3');

# The terminal output with line ends as "\n" (in Raku, "\r\n" is one grapheme).
sub plain(Str:D $s) { $s.subst("\r\n", "\n", :g).subst("\r", "", :g) }

# Runs irak under script(1), types $line then $enter, and returns what the
# terminal got once &until holds for it (or the session ends, or 30 seconds
# pass). irak runs a complete line on a second Enter (the first shows its
# feedback), and an incomplete one on the first. irak holds a submission's
# output to page it; $pager is RAK_PAGER, and '' turns paging off.
sub session(Str:D $line, :&until!, :$editor = True, :$disable, :$enter = "\r\r",
            :$pager = 'cat') {
    my %env = %*ENV;
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAKUDO_NO_VERSION>   = 1;
    %env<RAKUDO_HIST>         = $*TMPDIR.add("irak-osc133-hist-$*PID").absolute;
    %env<RAKUDO_DISABLE_OSC133>:delete;
    %env<RAKUDO_DISABLE_OSC133> = 1 if $disable;
    %env<RAKUDO_LINE_EDITOR>    = $editor ?? 'LineEditor' !! 'none';
    %env<RAK_PAGER>             = $pager;

    my $proc  = Proc::Async.new(:w, $script, '-qec',
                  "'{$*EXECUTABLE.absolute}'", '/dev/null');
    my $out   = '';
    my $typed = False;
    my $seen  = 0;
    my $met   = Promise.new;
    # Bytes: a streaming text decoder holds back the last character, and the
    # editor waits for an answer to the \e[6n that ends its output.
    $proc.stdout(:bin).tap: -> $chunk {
        $out ~= $chunk.decode('latin-1');
        if $editor {
            # answer the cursor position, then the terminal size, then type
            while $seen < +$out.indices("\e[6n") {
                ++$seen;
                if $seen == 1 { $proc.print("\e[1;6R") }
                elsif $seen == 2 { $proc.print("\e[24;80R$line$enter"); $typed = True }
            }
        }
        elsif !$typed && $out.contains('] > ') {
            $proc.print("$line\r");
            $typed = True;
        }
        $met.keep if $typed && $met.status ~~ Planned && until(plain($out));
    }
    $proc.stderr(:bin).tap: -> $ { };
    my $done = $proc.start(:ENV(%env));
    await Promise.anyof($done, $met, Promise.in(30));
    $proc.kill(SIGKILL) unless $done;
    await Promise.anyof($done, Promise.in(5));   # reap; a killed Proc would throw if sunk
    %env<RAKUDO_HIST>.IO.unlink;
    plain($out)
}

my $out = session('1 + 1', :until(*.contains($D0)));
ok $out.contains($A ~ '[0] >' ~ $B), 'A and B wrap the prompt';
like $out, / $B .*? $C 2 \n $D0 /, 'the value comes between C and D;0';
ok $out.ends-with($A ~ '[1] >' ~ $B), 'the next prompt gets A and B';

$out = session('die "boom"', :until(*.contains($D1)));
like $out, / $C .*? boom .*? $D1 /, 'a thrown error ends with D;1';

$out = session('sh -c "exit 3"', :until(*.contains('133;D')));
like $out, / $C .*? 'exit 3' .*? $D3 /, q[a command ends with its exit status, from $?];

$out = session('!7', :until(*.contains('133;D')));
like $out, / $C 'irak: no submission 7' \n $D1 /, 'a failed directive ends with D;1';

$out = session('my @a = (1,', :enter("\r"), :until(*.ends-with("\n*")));
ok $out.ends-with("\n*"),        'an incomplete submission gets a continuation prompt';
is +$out.indices($A), 1,         'the continuation prompt gets no A';
is +$out.indices($B), 1,         'the continuation prompt gets no B';
nok $out.contains($C),           'an incomplete submission gets no C';
nok $out.contains('133;D'),      'an incomplete submission gets no D';

$out = session('exit', :until({ False }));
ok $out.contains($C),            '`exit` gets a C';
nok $out.contains('133;D'),      '`exit` ends irak before any D';

$out = session('say 6 * 7', :until(*.contains('133;D')));
like $out, / $C 42 \n $D0 /, 'printed output comes between C and D;0';

$out = session('1 + 41', :disable, :until(*.contains('[1] >')));
ok $out.contains('42') && !$out.contains("\e]133;"),
  'RAKUDO_DISABLE_OSC133 turns the marks off';

$out = session('1 + 41', :!editor, :until(*.contains('[1] >')));
ok $out.contains('42') && !$out.contains("\e]133;"),
  'no marks without the line editor';

$out = session('say 6 * 7', :pager(''), :until(*.contains('133;D')));
like $out, / $C 42 \n $D0 /, 'without paging, output still comes between C and D;0';
