use Test;

# irak: a submission whose value is what a load decoded from JSON (a .json
# file, or a URL answering JSON) shows it as the formatter `.` does: indented
# JSON, in color on a terminal. The value still becomes the topic.
#
# The REPL needs a tty, so the session runs under script(1), without a line
# editor.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 6;

my $dir = $*TMPDIR.add("rak-load-json-$*PID");
$dir.mkdir;
LEAVE $dir.IO.dir>>.unlink, $dir.rmdir;
$dir.add('a.json').spurt: '{"name":"octocat","ids":[1,2]}';
$dir.add('a.txt').spurt: "plain\n";

sub session(*@lines) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAK_PAGER>           = '';
    my $feed = 'sleep 2; '
      ~ @lines.map({ "printf '%s\\r' '$_'; sleep 0.7; " }).join
      ~ "printf 'exit\\r'; sleep 0.5";
    my $cmd = "cd '$dir' && ($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
    run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g)
}

my $out = session '<a.json', '.name', '<a.txt', 'my %h <a.json';
my $plain = $out.subst(/\e '[' <[0..9;]>* 'm'/, '', :g);

like $plain, /'<a.json' \n '{' \n '  "ids": [' \n '    1,' \n '    2' \n '  ],' \n
              '  "name": "octocat"' \n '}' \n/,
  'a JSON load shows indented JSON';
ok $out ~~ / \e '[' <[0..9;]>+ 'm' '"name"' /, 'in color, as the formatter';
like $plain, /'.name' \n 'octocat' \n/, 'the loaded value is the topic';
like $plain, /'<a.txt' \n 'plain' \n/, 'a load without a format shows as before';
like $plain, /'my %h <a.json' \n '{ids => [1 2], name => octocat}' \n/,
  'a load into a variable shows as before';
unlike $plain, /'Type check' | 'Error'/, 'no error';
