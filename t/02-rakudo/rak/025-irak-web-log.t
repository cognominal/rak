use Test;
use lib 't/packages/RakHTTPFixture/lib';
use RakHTTPFixture;

# irak's web log, @*IWEB (PLANS/features/url-targets.md): one element per
# HTTP request of a URL target, with the submission's number, source and
# value. It keeps the last 100 requests, or fewer under 10 MB of JSON.
#
# The REPL needs a tty, so the session runs under script(1), without a line
# editor. A local fixture stands in for the network.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 13;

my $srv = RakHTTPFixture.new(routes => {
    'GET /obj'  => (200, 'application/json', '{"name": "rak"}'),
    'GET /boom' => (500, 'text/plain', "it broke\n"),
    'GET /big'  => (200, 'text/plain', 'x' x 4_000_000),
});
my $base = $srv.base;

# A token from the headers file, which the log must hide.
my $config = $*TMPDIR.add("rak-web-log-$*PID");
$config.add('rak').mkdir;
$config.add('rak/http-headers.json').spurt:
  q[{ '127.0.0.1': { auth: 's3cret-t0ken' } }];
LEAVE {
    $config.add('rak/http-headers.json').unlink;
    $config.add('rak').rmdir;
    $config.rmdir;
}

sub session(*@lines) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<RAK_PAGER>           = '';
    %env<XDG_CONFIG_HOME>     = ~$config;
    my $feed = 'sleep 2; '
      # a number is a longer wait, for a slow submission
      ~ @lines.map({ $_ ~~ Int ?? "sleep $_; " !! "printf '%s\\r' '$_'; sleep 1; " }).join
      ~ "printf 'exit\\r'; sleep 0.5";
    my $cmd = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
    run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g)
}

my $out = session
  "my %h <$base/obj; %h.name",
  '1 + 1',
  "<$base/boom",
  'say "N: ", @*IWEB->elems',
  'given @*IWEB[0] { say "A: ", (.idx, .method, .status, .url, .body.name).join(" ") }',
  'given @*IWEB[0] { say "S: ", .subm; say "R: ", .res; say "I: ", .in.Authorization }',
  'say "O: ", @*IWEB[0].out->keys->map({ $_->lc })->sort->join(",")',
  'given @*IWEB[1] { say "B: ", (.idx, .status).join(" "); say "E: ", .res }',
  'for ^105 { my %x <' ~ $base ~ '/obj }', 8,
  'say "L: ", @*IWEB->elems, " ", @*IWEB[0].subm',
  "for ^3 \{ my \$x <$base/big }", 3,
  'say "M: ", @*IWEB->elems';

like   $out, /'N: 2' \n/, 'each request is logged, a submission without one adds none';
like   $out, /"A: 0 GET 200 $base/obj rak" \n/, 'idx, method, status, url and the decoded body';
like   $out, /"S: my %h <$base/obj; %h.name" \n/, 'subm is the source';
like   $out, /'R: "rak"' \n/, "res is the submission's value, as the formatter writes it";
like   $out, /'I: ***' \n/, 'a token in the request headers is hidden';
unlike $out, /'s3cret'/, 'the token never shows';
like   $out, /'O: ' \N* 'content-type'/, 'out holds the response headers';
like   $out, /'B: 2 500' \n/, 'a failed request is logged with its status';
like   $out, /'E: ' \N* 'HTTP 500: it broke'/, "and the error's message as res";
like   $out, /'L: 100 ' / , 'the log keeps 100 requests';
like   $out, /'L: 100 for ^105' /, 'the oldest go first';
like   $out, /'M: 2' \n/, 'and less than 10 MB of JSON';
is     $srv.requests.grep(*<path> eq '/obj').elems, 106, 'the fixture saw every request';
