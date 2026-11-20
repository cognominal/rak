# A local HTTP/1.1 server for the URL target tests: it serves canned responses
# and records every request, so tests never touch the network.
#
#     my $srv = RakHTTPFixture.new(routes => {
#         'GET /obj' => (200, 'application/json', '{"a": 1}'),
#     });
#     my $base = $srv.base;              # http://127.0.0.1:PORT
#     ... $srv.requests[0]<method path headers body> ...
#
# A route's response is (status, content-type, body). An unknown route is a
# 404 with a GitHub-shaped JSON body.
unit class RakHTTPFixture;

has %.routes;
has @!requests;
has $.port;
has $!tap;
has Lock $!lock .= new;

submethod TWEAK() {
    my $listener = IO::Socket::Async.listen('127.0.0.1', 0);
    $!tap = $listener.tap: -> $conn { self!serve($conn) };
    $!port = await $!tap.socket-port;
}

method base() { "http://127.0.0.1:$!port" }

method requests() { $!lock.protect: { @!requests.List } }

method last() { self.requests.tail }

method stop() { $!tap.close }

method !serve($conn) {
    my $buf = Buf.new;
    $conn.Supply(:bin).tap: -> $chunk {
        $buf.append: $chunk;
        with self!parse($buf) -> %req {
            $!lock.protect: { @!requests.push: %req };
            my ($status, $type, $body) =
                %!routes{"%req<method> %req<path>"}
                  // (404, 'application/json', '{"message": "Not Found"}');
            my $payload = $body.encode;
            my $head = "HTTP/1.1 $status X\r\n"
              ~ ($type ?? "Content-Type: $type\r\n" !! '')
              ~ "Content-Length: {$payload.elems}\r\n"
              ~ "Connection: close\r\n\r\n";
            await $conn.write: $head.encode ~ $payload;
            $conn.close;
        }
    }
}

# The request once it is complete, or Nil.
method !parse(Buf $buf) {
    # A byte offset: "\r\n" is one grapheme, so a Str index would not do.
    my $end = (0 .. $buf.elems - 4).first({
        $buf[$_] == 13 && $buf[$_ + 1] == 10 && $buf[$_ + 2] == 13 && $buf[$_ + 3] == 10
    }) // return Nil;
    my @lines = $buf.subbuf(0, $end).decode('latin-1').split("\r\n");
    my ($method, $path) = @lines.shift.words;
    my %headers = @lines.map: { my ($k, $v) = .split(':', 2); $k.trim.lc => $v.trim };
    my $length = (%headers<content-length> // 0).Int;
    return Nil if $buf.elems < $end + 4 + $length;
    my $body = $buf.subbuf($end + 4, $length).decode('utf8');
    %( :$method, :$path, :%headers, :$body )
}
