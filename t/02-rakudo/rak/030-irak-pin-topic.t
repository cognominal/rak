use Test;

# irak: a lone `-` pins the topic, or unpins it. While pinned, submissions
# run and show their values but `$_` stays, except after a topic-setting
# submission (`! ` before it) or `!!n`. The pin stays on after both.
#
# The REPL needs a tty, so the session runs under script(1), without a line
# editor.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 19;

sub session(*@lines) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAK_PAGER>           = '';
    my $feed = 'sleep 2; '
      ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.7; " }).join
      ~ "printf 'exit\\r'; sleep 0.5";
    my $cmd = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
    run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g)
}

my $out = session
  '{ a => { b => 42 }, c => 7 }',   # [0]
  '-',                              # pins
  '.a',                             # [1]
  '.c',                             # [2]
  'say "pinned: ", $_<c>',
  '! .a',                           # [3]
  '.b',                             # [4]
  'say "set: ", $_<b>',
  '!!2',
  'say "recalled: ", $_',
  '! 10',                           # [5]
  '20',                             # [6]
  'say "ten: ", $_',
  '!!6',
  '!5',                             # [7]
  'say "replayed: ", $_',
  '-',                              # unpins
  '$_ + 1',                         # [8]
  'say "unpinned: ", $_';

like $out, /'irak: topic pinned'/, 'a lone `-` pins the topic';
like $out, /'irak: topic pinned' \n '[1] >- .a'/, 'the toggle gets no number, the prompt ends in `-`';
like $out, /'[5] >- ! 10'/, 'the prompt keeps its `-` while pinned';
like $out, /'.a' \n '{b => 42}' \n/, 'a pinned submission still shows its value';
like $out, /'.c' \n '7' \n/, 'the topic is still the hash';
like $out, /'pinned: 7'/, 'two submissions leave a pinned topic alone';
like $out, /'! .a' \n '{b => 42}' \n/, '`! ` is stripped and the value shown';
like $out, /'set: 42'/, '`! ` sets a pinned topic, which stays pinned';
like $out, /'recalled: 7'/, '`!!n` sets a pinned topic';
like $out, /'ten: 10'/, 'the pin holds the value `! ` set';
like $out, /'!5' \n '! 10' \n '10' \n/, '`!n` replays the `! ` source';
like $out, /'replayed: 10'/, 'the replay sets the pinned topic';
like $out, /'irak: topic unpinned'/, 'a second lone `-` unpins it';
like $out, /'irak: topic unpinned' \n '[8] > $_ + 1'/, 'unpinned, the prompt loses its `-`';
like $out, /'unpinned: 11'/, 'unpinned, a submission sets the topic again';

# A comment may follow the lone `-`. `#` is also the native-int sigil, so
# `- #n` stays a topic-keeping submission that shows `#n`.
my $commented = session
  '{ c => 7 }',                     # [0]
  '-   # pin it',
  'my #n = 3',                      # [1]
  '- #n',                           # [2]
  'say "kept: ", $_<c>',
  '- #',
  '$_';                             # [3]

like $commented, /'-   # pin it' \n 'irak: topic pinned'/, 'a comment may follow the pinning `-`';
like $commented, /'kept: 7'/, 'the topic commented `-` pinned stays';
like $commented, /'- #n' \n '3' \n/, '`- #n` still shows the native int';
like $commented, /'- #' \n 'irak: topic unpinned'/, 'an empty comment may follow the `-` too';
