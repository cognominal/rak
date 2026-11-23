use Test;

# irak: a submission starting with `- ` runs with that prefix stripped, and
# its value does not become the topic, so `$_` can be explored in place.
#
# The REPL needs a tty, so the session runs under script(1), without a line
# editor.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 6;

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
  '{ a => { b => 42 }, c => 7 }',
  '- .a',
  '- .a.b',
  '.c',
  'say "topic: ", $_',
  '- 1 + 1',
  '!4',
  'say "after: ", $_';

like $out, /'- .a' \n '{b => 42}' \n/, '`- ` is stripped and the value shown';
like $out, /'- .a.b' \n '42' \n/, 'the topic is still the hash';
like $out, /'.c' \n '7' \n/, 'the hash is still there after two `- ` submissions';
like $out, /'topic: 7'/, 'a plain submission still sets the topic';
like $out, /'!4' \n '- 1 + 1' \n '2' \n/, '`!n` replays the `- ` source';
like $out, /'after: 7'/, '`- ` and its replay leave the topic alone';
