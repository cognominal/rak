# YAML (rak-plans/features/yaml.md): rak's own loader and writer, beside the
# JSON decoder. Files follow nushell's conventions: `!filesize` bytes,
# `!duration` nanoseconds, `!!timestamp`, `!range`, `!!binary`. Untagged
# scalars follow YAML 1.2's core schema; mappings keep their key order.

# A tag the loader does not know.
my class X::Rak::Format::Decode::Tag is X::Rak::Format::Decode {
    has Str $.tag;
    method message() {
        "$.target: unknown tag $!tag at line $.line, column $.column "
          ~ "(from-yaml --ignore-tags loads it untagged)"
    }
}

my class Rakudo::Internals::RakYAML is implementation-detail {
    has str $!text;
    has int $!pos;
    has int $!end;
    has Str $!target;
    has Bool $!ignore-tags;
    has %!anchors;
    has int $!nl;           # newlines crossed by the last !next
    has int $!comment;      # whether the last !next skipped a comment

    submethod BUILD(Str:D :$text, Str:D :$target, :$ignore-tags) {
        $!text        = $text.subst("\r\n", "\n", :g);
        $!end         = nqp::chars($!text);
        $!target      = $target;
        $!ignore-tags = ?$ignore-tags;
    }

    # --- decoding -----------------------------------------------------------

    # A stream of one document loads as that document, of several as the list
    # of them (nushell's `--multiple auto`), of none as Nil.
    method decode(Str:D $text, Str:D $target, :$ignore-tags) {
        my @docs = self.new(:$text, :$target, :$ignore-tags)!stream;
        @docs == 0 ?? Nil !! @docs == 1 ?? @docs[0] !! @docs
    }

    method !stream() {
        my @docs;
        $!pos = 1 if nqp::eqat($!text, "\x[FEFF]", 0);
        loop {
            my int $col = self!next;
            # directives, at the start of a line
            while $col == 0 && self!char eq '%' {
                self!fail('%TAG directives are not supported') if self!at('%TAG');
                self!to-eol;
                $col = self!next;
            }
            last if $!pos >= $!end;
            if self!marker('...') {
                $!pos = $!pos + 3;
                next;
            }
            my $explicit = False;
            if self!marker('---') {
                $!pos = $!pos + 3;
                $explicit = True;
            }
            %!anchors = ();
            @docs.push: self!node(-1, :top);
            $col = self!next;
            if self!marker('...') {
                $!pos = $!pos + 3;
            }
            elsif $!pos < $!end && !self!marker('---') {
                self!fail('unexpected text after the document');
            }
        }
        @docs
    }

    method !fail(Str:D $reason, int $at = $!pos) is hidden-from-backtrace {
        X::Rak::Format::Decode.new(
          :$!target, :format<yaml>, :$reason, |self!where($at)
        ).throw
    }

    method !where(int $at) {
        my int $p = $at min $!end;
        my str $before = nqp::substr($!text, 0, $p);
        my int $line = 1;
        my int $i = nqp::index($before, "\n");
        my int $start = 0;
        while $i >= 0 {
            ++$line;
            $start = $i + 1;
            $i = nqp::index($before, "\n", $i + 1);
        }
        %(:$line, :column($p - $start + 1))
    }

    method !char() { $!pos < $!end ?? nqp::substr($!text, $!pos, 1) !! '' }
    method !char-at(int $p) { $p < $!end && $p >= 0 ?? nqp::substr($!text, $p, 1) !! '' }
    method !at(Str:D $s) { nqp::eqat($!text, $s, $!pos) }

    method !column(int $p = $!pos) {
        my int $nl = $p > 0 ?? nqp::rindex($!text, "\n", $p - 1) !! -1;
        $p - $nl - 1
    }

    # A blank: a space, a tab, a line end, or the end of the text.
    method !blank-at(int $p) {
        my str $c = self!char-at($p);
        $c eq '' || $c eq ' ' || $c eq "\t" || $c eq "\n"
    }

    # `---` or `...` at the start of a line, followed by a blank.
    method !marker(Str:D $m) {
        self!column == 0 && self!at($m) && self!blank-at($!pos + 3)
    }

    method !to-eol() {
        my int $i = nqp::index($!text, "\n", $!pos);
        $!pos = $i < 0 ?? $!end !! $i;
    }

    # Skips spaces, comments and line ends up to the next content; the
    # column of that content, or -1 at the end of the text or a document
    # marker. Sets $!nl to the number of line ends crossed.
    method !next(--> int) {
        $!nl = 0;
        $!comment = 0;
        loop {
            my str $c = self!char;
            if $c eq ' ' || $c eq "\t" {
                ++$!pos;
            }
            elsif $c eq '#' && ($!pos == 0 || self!blank-at($!pos - 1)) {
                $!comment = 1;
                self!to-eol;
            }
            elsif $c eq "\n" {
                ++$!pos;
                ++$!nl;
            }
            elsif $c eq '' {
                return -1;
            }
            else {
                my int $col = self!column;
                return -1 if $col == 0 && (self!marker('---') || self!marker('...'));
                return $col;
            }
        }
    }

    # A `-` that starts a sequence item.
    method !dash() { self!char eq '-' && self!blank-at($!pos + 1) }

    # One node. $parent is the indentation of the collection holding it; a
    # node on a later line must be more indented, except that a sequence may
    # sit at its key's indentation (`key:` then `- item`).
    method !node(int $parent, :$map-value, :$top) {
        my $tag;
        my int $tag-at = -1;
        my $anchor;
        my int $nl = 0;
        my int $col = self!next;
        $nl = 1 if $!nl;
        loop {
            if $col < 0 || $nl && ($col < $parent
                 || $col == $parent && !($map-value && self!dash)) {
                return self!scalar-value($tag, $tag-at, '', True, $anchor)
            }
            my str $c = self!char;
            if $c eq '!' {
                self!fail('a node has two tags') if $tag.defined;
                $tag-at = $!pos;
                $tag = self!tag;
            }
            elsif $c eq '&' {
                ++$!pos;
                $anchor = self!name;
            }
            else { last }
            $col = self!next;
            $nl = 1 if $!nl;
        }
        my str $c = self!char;
        my $props = $tag.defined || $anchor.defined;
        if $c eq '*' {
            self!fail('an alias cannot have a tag or an anchor') if $props;
            my int $at = $!pos;
            ++$!pos;
            my $name = self!name;
            self!fail("unknown alias *$name", $at) unless %!anchors{$name}:exists;
            if self!key-ahead {
                self!fail('aliases as keys are not supported', $at);
            }
            return %!anchors{$name};
        }
        if self!dash {
            self!fail('a sequence cannot start on the line of its key')
              if $map-value && !$nl;
            return self!collection($tag, $tag-at, $anchor, 'seq', self!block-seq($col));
        }
        if $c eq '?' && self!blank-at($!pos + 1) {
            self!fail('complex keys (? key) are not supported');
        }
        if $c eq '|' || $c eq '>' {
            return self!scalar-value($tag, $tag-at, self!block-scalar($parent), False, $anchor);
        }
        if self!key-ahead {
            self!fail('a mapping cannot start on the line of its key')
              if $map-value && !$nl;
            self!fail('complex keys are not supported')
              if $c eq '[' || $c eq '{';
            return self!collection($tag, $tag-at, $anchor, 'map', self!block-map($col));
        }
        if $c eq '[' || $c eq '{' {
            my \v = $c eq '[' ?? self!flow-seq !! self!flow-map;
            return self!collection($tag, $tag-at, $anchor, $c eq '[' ?? 'seq' !! 'map', v);
        }
        if $c eq '"' || $c eq "'" {
            return self!scalar-value($tag, $tag-at, self!quoted, False, $anchor);
        }
        self!scalar-value($tag, $tag-at, self!plain($parent), True, $anchor)
    }

    # A tag: `!name`, `!!name`, `!<verbatim>` or `!`.
    method !tag() {
        my int $start = $!pos;
        if self!at('!<') {
            my int $close = nqp::index($!text, '>', $!pos);
            self!fail('unterminated tag') if $close < 0;
            $!pos = $close + 1;
            return nqp::substr($!text, $start + 2, $close - $start - 2);
        }
        ++$!pos;
        ++$!pos while $!pos < $!end && !self!blank-at($!pos)
          && nqp::index(',[]{}', self!char) < 0;
        my str $t = nqp::substr($!text, $start, $!pos - $start);
        nqp::eqat($t, '!!', 0)
          ?? 'tag:yaml.org,2002:' ~ nqp::substr($t, 2)
          !! $t
    }

    method !name() {
        my int $start = $!pos;
        ++$!pos while $!pos < $!end && !self!blank-at($!pos)
          && nqp::index(',[]{}', self!char) < 0;
        self!fail('an anchor or alias needs a name') if $!pos == $start;
        nqp::substr($!text, $start, $!pos - $start)
    }

    # Whether a block mapping key starts here: a key on this line, then `:`
    # and a blank.
    method !key-ahead() {
        my int $save = $!pos;
        LEAVE $!pos = $save;
        my str $c = self!char;
        if $c eq '"' || $c eq "'" {
            my int $line-end = nqp::index($!text, "\n", $!pos);
            $line-end = $!end if $line-end < 0;
            my $ok = try { self!quoted; True };
            return False unless $ok && $!pos <= $line-end;
            ++$!pos while self!char eq ' ' || self!char eq "\t";
            return self!char eq ':' && self!blank-at($!pos + 1);
        }
        if $c eq '[' || $c eq '{' {
            my $ok = try { $c eq '[' ?? self!flow-seq !! self!flow-map; True };
            return False unless $ok;
            ++$!pos while self!char eq ' ' || self!char eq "\t";
            return self!char eq ':' && self!blank-at($!pos + 1);
        }
        while $!pos < $!end {
            my str $d = self!char;
            return False if $d eq "\n";
            return False if $d eq '#' && self!blank-at($!pos - 1);
            return True if $d eq ':' && self!blank-at($!pos + 1);
            ++$!pos;
        }
        False
    }

    # A block mapping whose keys are at column $col.
    method !block-map(int $col) {
        my %h is Hash::Ordered;
        loop {
            my int $at = $!pos;
            my str $c = self!char;
            my $key = $c eq '"' || $c eq "'"
              ?? self!quoted
              !! self!plain-key;
            self!fail('merge keys (<<) are not supported', $at)
              if $key eq '<<' && $c ne '"' && $c ne "'";
            ++$!pos while self!char eq ' ' || self!char eq "\t";
            self!fail("expected ':' after a key") unless self!char eq ':';
            ++$!pos;
            self!fail("duplicate key '$key'", $at) if %h{$key}:exists;
            %h{$key} = self!node($col, :map-value);
            my int $next = self!next;
            last if $next < $col;
            self!fail('bad indentation of a mapping key') if $next > $col;
            self!fail('expected a key, found a sequence item') if self!dash;
            self!fail('expected a key') unless self!key-ahead;
        }
        %h
    }

    method !plain-key() {
        my int $start = $!pos;
        ++$!pos until self!char eq ':' && self!blank-at($!pos + 1);
        nqp::substr($!text, $start, $!pos - $start).trim-trailing
    }

    # A block sequence whose dashes are at column $col.
    method !block-seq(int $col) {
        my @a;
        loop {
            ++$!pos;     # the dash
            @a[@a.elems] = self!node($col);
            my int $next = self!next;
            last if $next < $col;
            self!fail('bad indentation of a sequence item') if $next > $col;
            last unless self!dash;
        }
        @a
    }

    # A plain scalar, perhaps over several lines, which are folded.
    method !plain(int $parent) {
        my str $out = self!plain-line(False);
        loop {
            my int $save = $!pos;
            my int $col = self!next;
            if $col > $parent && $!nl && !$!comment && !self!dash && !self!key-ahead {
                $out = $out ~ ($!nl > 1 ?? nqp::x("\n", $!nl - 1) !! ' ')
                  ~ self!plain-line(False);
            }
            else {
                $!pos = $save;
                last;
            }
        }
        $out
    }

    # The rest of a plain scalar on this line; in flow context it also ends
    # at `,`, `[`, `]`, `{`, `}` and `: `.
    method !plain-line($flow) {
        my int $start = $!pos;
        while $!pos < $!end {
            my str $c = self!char;
            last if $c eq "\n";
            last if $c eq '#' && self!blank-at($!pos - 1);
            last if $c eq ':' && (self!blank-at($!pos + 1)
              || $flow && nqp::index(',[]{}', self!char-at($!pos + 1)) >= 0);
            last if $flow && nqp::index(',[]{}', $c) >= 0;
            ++$!pos;
        }
        nqp::substr($!text, $start, $!pos - $start).trim
    }

    # A single- or double-quoted scalar; line breaks fold as in YAML.
    method !quoted() {
        my int $at = $!pos;
        my str $q = self!char;
        ++$!pos;
        my @parts;
        my str $buf = '';
        loop {
            self!fail('unterminated quoted string', $at) if $!pos >= $!end;
            my str $c = self!char;
            if $q eq "'" && $c eq "'" {
                if self!char-at($!pos + 1) eq "'" {
                    $buf = $buf ~ "'";
                    $!pos = $!pos + 2;
                    next;
                }
                ++$!pos;
                last;
            }
            if $q eq '"' && $c eq '"' {
                ++$!pos;
                last;
            }
            if $q eq '"' && $c eq '\\' {
                my str $e = self!char-at($!pos + 1);
                if $e eq "\n" {
                    # an escaped line break: the break and the next line's
                    # indentation are dropped
                    $!pos = $!pos + 2;
                    ++$!pos while self!char eq ' ' || self!char eq "\t";
                    next;
                }
                $buf = $buf ~ self!escape;
                next;
            }
            if $c eq "\n" {
                $buf = $buf.trim-trailing;
                my int $breaks = 0;
                while self!char eq "\n" || self!char eq ' ' || self!char eq "\t" {
                    ++$breaks if self!char eq "\n";
                    ++$!pos;
                }
                $buf = $buf ~ ($breaks > 1 ?? nqp::x("\n", $breaks - 1) !! ' ');
                next;
            }
            $buf = $buf ~ $c;
            ++$!pos;
        }
        $buf
    }

    method !escape() {
        my int $at = $!pos;
        my str $e = self!char-at($!pos + 1);
        $!pos = $!pos + 2;
        my %simple := {
          '0' => "\0", 'a' => "\a", 'b' => "\b", 't' => "\t", "\t" => "\t",
          'n' => "\n", 'v' => "\x0B", 'f' => "\f", 'r' => "\r", 'e' => "\e",
          ' ' => ' ', '"' => '"', '/' => '/', '\\' => '\\',
          'N' => "\x85", '_' => "\xA0", 'L' => "\x2028", 'P' => "\x2029",
        };
        return %simple{$e} if %simple{$e}:exists;
        my int $n = $e eq 'x' ?? 2 !! $e eq 'u' ?? 4 !! $e eq 'U' ?? 8 !! 0;
        self!fail("unknown escape \\$e", $at) unless $n;
        my str $hex = nqp::substr($!text, $!pos, $n);
        self!fail("bad escape \\$e$hex", $at)
          unless nqp::chars($hex) == $n && $hex ~~ /^ <[0..9a..fA..F]>+ $/;
        $!pos = $!pos + $n;
        chr(:16($hex))
    }

    # A `|` or `>` block scalar. Content lines are more indented than
    # $parent.
    method !block-scalar(int $parent) {
        my int $at = $!pos;
        my $folded = self!char eq '>';
        ++$!pos;
        my $chomp = 'clip';
        my int $explicit = 0;
        for ^2 {
            my str $c = self!char;
            if $c eq '-' { $chomp = 'strip'; ++$!pos }
            elsif $c eq '+' { $chomp = 'keep'; ++$!pos }
            elsif nqp::index('123456789', $c) >= 0 && $c ne '' {
                $explicit = +$c;
                ++$!pos;
            }
        }
        ++$!pos while self!char eq ' ' || self!char eq "\t";
        if self!char eq '#' { self!to-eol }
        self!fail('expected a line end after a block scalar indicator')
          unless self!char eq "\n" || self!char eq '';
        ++$!pos if self!char eq "\n";

        my int $indent = $explicit ?? ($parent < 0 ?? 0 !! $parent) + $explicit !! -1;
        my @lines;
        while $!pos < $!end {
            my int $eol = nqp::index($!text, "\n", $!pos);
            $eol = $!end if $eol < 0;
            my str $line = nqp::substr($!text, $!pos, $eol - $!pos);
            my int $spaces = 0;
            ++$spaces while nqp::eqat($line, ' ', $spaces);
            if $spaces == nqp::chars($line) {
                # an empty line
                @lines.push: $indent >= 0 && $spaces > $indent
                  ?? nqp::substr($line, $indent) !! '';
            }
            else {
                $indent = $spaces if $indent < 0;
                last if $spaces < $indent || $spaces <= $parent;
                last if $spaces == 0 && (nqp::eqat($line, '---', 0) || nqp::eqat($line, '...', 0))
                  && (nqp::chars($line) == 3 || nqp::eqat($line, ' ', 3));
                @lines.push: nqp::substr($line, $indent);
            }
            $!pos = $eol < $!end ?? $eol + 1 !! $!end;
        }
        # Trailing empty lines belong to the chomping, not to the content;
        # the position goes back to the first of them.
        my int $trailing = 0;
        while @lines && @lines.tail eq '' {
            @lines.pop;
            ++$trailing;
        }
        if $trailing {
            my int $p = $!pos;
            my int $back = $trailing;
            $back = $back - 1 if $p == $!end && !nqp::eqat($!text, "\n", $!end - 1);
            while $back > 0 && $p > 0 {
                --$p;
                $p = nqp::rindex($!text, "\n", $p - 1) + 1;
                --$back;
            }
            $!pos = $p;
        }
        my str $body = '';
        if $folded {
            my int $breaks = 0;
            my $prev-normal = False;
            my $first = True;
            for @lines -> $l {
                if $l eq '' { ++$breaks; next }
                my $normal = !$l.starts-with(' ') && !$l.starts-with("\t");
                $body = $first
                  ?? nqp::x("\n", $breaks)
                  !! $prev-normal && $normal
                    ?? $body ~ ($breaks ?? nqp::x("\n", $breaks) !! ' ')
                    !! $body ~ nqp::x("\n", $breaks + 1);
                $body = $body ~ $l;
                $breaks = 0;
                $prev-normal = $normal;
                $first = False;
            }
        }
        else {
            $body = @lines.join("\n");
        }
        $chomp eq 'strip'  ?? $body
          !! $chomp eq 'keep' ?? $body ~ nqp::x("\n", ($body ne '' ?? 1 !! 0) + $trailing)
          !! $body ne ''      ?? $body ~ "\n"
          !! ''
    }

    # --- flow collections ---------------------------------------------------

    method !flow-ws() {
        loop {
            my str $c = self!char;
            if $c eq ' ' || $c eq "\t" || $c eq "\n" { ++$!pos }
            elsif $c eq '#' && self!blank-at($!pos - 1) { self!to-eol }
            else { last }
        }
    }

    method !flow-node() {
        self!flow-ws;
        my $tag;
        my int $tag-at = -1;
        my $anchor;
        loop {
            my str $c = self!char;
            if $c eq '!' {
                self!fail('a node has two tags') if $tag.defined;
                $tag-at = $!pos;
                $tag = self!tag;
            }
            elsif $c eq '&' { ++$!pos; $anchor = self!name }
            else { last }
            self!flow-ws;
        }
        my str $c = self!char;
        self!fail('unexpected end of input in a flow collection') if $c eq '';
        if $c eq '*' {
            my int $at = $!pos;
            ++$!pos;
            my $name = self!name;
            self!fail("unknown alias *$name", $at) unless %!anchors{$name}:exists;
            return %!anchors{$name};
        }
        if $c eq '[' { return self!collection($tag, $tag-at, $anchor, 'seq', self!flow-seq) }
        if $c eq '{' { return self!collection($tag, $tag-at, $anchor, 'map', self!flow-map) }
        if $c eq '"' || $c eq "'" {
            return self!scalar-value($tag, $tag-at, self!quoted, False, $anchor)
        }
        if $c eq ',' || $c eq ']' || $c eq '}' {
            return self!scalar-value($tag, $tag-at, '', True, $anchor)
        }
        self!scalar-value($tag, $tag-at, self!flow-plain, True, $anchor)
    }

    # A plain scalar in a flow collection, perhaps over several lines.
    method !flow-plain() {
        my str $out = self!plain-line(True);
        loop {
            last unless self!char eq "\n";
            my int $save = $!pos;
            self!flow-ws;
            my str $c = self!char;
            if $c eq '' || nqp::index(',[]{}#', $c) >= 0 || $c eq ':' {
                $!pos = $save;
                last;
            }
            $out = $out ~ ' ' ~ self!plain-line(True);
        }
        $out
    }

    method !flow-seq() {
        my int $at = $!pos;
        ++$!pos;
        my @a;
        loop {
            self!flow-ws;
            self!fail('unterminated flow sequence', $at) if $!pos >= $!end;
            if self!char eq ']' { ++$!pos; last }
            my \item = self!flow-node;
            self!flow-ws;
            if self!char eq ':' {
                # a one-pair mapping, `[a: 1]`
                ++$!pos;
                my %h is Hash::Ordered;
                %h{item.Str} = self!flow-node;
                @a[@a.elems] = %h;
                self!flow-ws;
            }
            else {
                @a[@a.elems] = item;
            }
            if self!char eq ',' { ++$!pos }
            elsif self!char ne ']' {
                self!fail("expected ',' or ']'");
            }
        }
        @a
    }

    method !flow-map() {
        my int $at = $!pos;
        ++$!pos;
        my %h is Hash::Ordered;
        loop {
            self!flow-ws;
            self!fail('unterminated flow mapping', $at) if $!pos >= $!end;
            if self!char eq '}' { ++$!pos; last }
            self!fail('complex keys (? key) are not supported')
              if self!char eq '?' && self!blank-at($!pos + 1);
            my int $key-at = $!pos;
            my str $c = self!char;
            my $key = $c eq '"' || $c eq "'" ?? self!quoted !! self!plain-line(True);
            self!fail('merge keys (<<) are not supported', $key-at)
              if $key eq '<<' && $c ne '"' && $c ne "'";
            self!fail("duplicate key '$key'", $key-at) if %h{$key}:exists;
            self!flow-ws;
            if self!char eq ':' {
                ++$!pos;
                self!flow-ws;
                %h{$key} = self!char eq ',' || self!char eq '}'
                  ?? Any
                  !! self!flow-node;
            }
            else {
                %h{$key} = Any;
            }
            self!flow-ws;
            if self!char eq ',' { ++$!pos }
            elsif self!char ne '}' {
                self!fail("expected ',' or '}'");
            }
        }
        %h
    }

    # --- tags and the core schema -------------------------------------------

    method !anchor($anchor, Mu \v) is raw {
        %!anchors{$anchor} := v if $anchor.defined;
        v
    }

    method !unknown($tag, int $at) is hidden-from-backtrace {
        X::Rak::Format::Decode::Tag.new(
          :$!target, :format<yaml>, :$tag, :reason("unknown tag $tag"), |self!where($at)
        ).throw
    }

    method !tag-name($tag) {
        $tag.starts-with('tag:yaml.org,2002:')
          ?? '!!' ~ $tag.substr(18)
          !! $tag
    }

    method !collection($tag, int $tag-at, $anchor, Str:D $kind, Mu \v) is raw {
        if $tag.defined && !$!ignore-tags {
            my $name = self!tag-name($tag);
            unless $name eq "!!$kind" || $name eq '!' {
                ($name eq any(<!filesize !duration !range !glob !cell-path
                    !!str !!int !!float !!bool !!null !!timestamp !!binary !!map !!seq>))
                  ?? self!fail("$name needs a scalar, found a {$kind eq 'map' ?? 'mapping' !! 'sequence'}", $tag-at)
                  !! self!unknown($name, $tag-at);
            }
        }
        self!anchor($anchor, v)
    }

    my $INT   = /^ <[-+]>? <[0..9]>+ $/;
    my $OCT   = /^ '0o' <[0..7]>+ $/;
    my $HEX   = /^ '0x' <[0..9a..fA..F]>+ $/;
    my $FLOAT = /^ <[-+]>? [ '.' <[0..9]>+ | <[0..9]>+ [ '.' <[0..9]>* ]? ] [ <[eE]> <[-+]>? <[0..9]>+ ]? $/;

    method !number(Str:D $s) {
        $s ~~ $INT || $s ~~ $OCT || $s ~~ $HEX ?? $s.Int
          !! $s ~~ $FLOAT ?? self!float($s)
          !! $s eq any(<.inf .Inf .INF +.inf +.Inf +.INF>) ?? Inf
          !! $s eq any(<-.inf -.Inf -.INF>) ?? -Inf
          !! $s eq any(<.nan .NaN .NAN>) ?? NaN
          !! Nil
    }

    method !float(Str:D $s) {
        my str $n = $s.starts-with('+') ?? $s.substr(1) !! $s;
        $n = $n.subst(/ '.' (<[eE]>) /, {".0$0"});
        $n = $n ~ '0' if $n.ends-with('.');
        $n = '0' ~ $n if $n.starts-with('.');
        $n = $n.subst(/^ '-.' /, '-0.');
        $n ~~ /<[eE]>/ ?? $n.Num !! $n.Rat
    }

    method !scalar-value($tag, int $tag-at, Str:D $text, $plain, $anchor) is raw {
        self!anchor($anchor, self!scalar($tag, $tag-at, $text, $plain))
    }

    method !scalar($tag, int $tag-at, Str:D $text, $plain) {
        my $name = $tag.defined && !$!ignore-tags ?? self!tag-name($tag) !! Nil;
        my sub bad($what) {
            self!fail("$name needs $what, got '$text'", $tag-at)
        }
        return self!untagged($text, $plain) without $name;
        given $name {
            when '!' | '!!str' | '!glob' | '!cell-path' { $text }
            when '!!null' { Any }
            when '!!bool' {
                $text eq any(<true True TRUE>) ?? True
                  !! $text eq any(<false False FALSE>) ?? False
                  !! bad('true or false')
            }
            when '!!int' {
                $text ~~ $INT || $text ~~ $OCT || $text ~~ $HEX ?? $text.Int !! bad('an integer')
            }
            when '!!float' {
                my \n = self!number($text);
                nqp::isconcrete(n) ?? (nqp::istype(n, Int) ?? n.Rat !! n) !! bad('a number')
            }
            when '!filesize' {
                $text ~~ $INT
                  ?? Rakudo::Internals::RakFilesize.new($text.Int)
                  !! bad('a number of bytes')
            }
            when '!duration' {
                $text ~~ $INT
                  ?? Duration.new($text.Int / 1_000_000_000)
                  !! bad('a number of nanoseconds')
            }
            when '!!timestamp' { self!timestamp($text) // bad('a date') }
            when '!range'      { self!range($text) // bad('a range such as 1..3') }
            when '!!binary'    { self!base64($text) // bad('base64') }
            when '!!map' | '!!seq' {
                self!fail("$name needs a {$name eq '!!map' ?? 'mapping' !! 'sequence'}, found a scalar", $tag-at)
            }
            default { self!unknown($name, $tag-at) }
        }
    }

    # YAML 1.2's core schema: null, booleans and numbers; anything else, and
    # any quoted or block scalar, is a string.
    method !untagged(Str:D $text, $plain) {
        return $text unless $plain;
        return Any if $text eq any('', '~', 'null', 'Null', 'NULL');
        return True if $text eq any(<true True TRUE>);
        return False if $text eq any(<false False FALSE>);
        my \n = self!number($text);
        nqp::isconcrete(n) ?? n !! $text
    }

    # A YAML timestamp: `2026-01-02`, `2026-01-02T03:04:05.5Z`,
    # `2001-12-14 21:59:43.10 -5`. Without a zone it is UTC.
    method !timestamp(Str:D $s) {
        my $m = $s.trim ~~ /^
          (\d**4 '-' \d**1..2 '-' \d**1..2)
          [ [ <[Tt]> | \h+ ] (\d**1..2 ':' \d**2 ':' \d**2 [ '.' \d+ ]?)
            \h* ( <[Zz]> | <[-+]> \d**1..2 [ ':'? \d**2 ]? )? ]?
        $/;
        return Nil unless $m;
        my @d = $m[0].Str.split('-');
        my $date = sprintf('%04d-%02d-%02d', |@d);
        return (try DateTime.new("{$date}T00:00:00Z")) // Nil unless $m[1].defined;
        my @t = $m[1].Str.split(':');
        my $time = sprintf('%02d:%s:%s', @t[0], @t[1], @t[2]);
        my $zone = 'Z';
        with $m[2] {
            my $z = .Str;
            unless $z eq 'Z' | 'z' {
                my $sign = $z.substr(0, 1);
                my ($h, $mm) = $z.substr(1).contains(':')
                  ?? $z.substr(1).split(':')
                  !! $z.chars > 3 ?? ($z.substr(1, 2), $z.substr(3)) !! ($z.substr(1), 0);
                $zone = sprintf('%s%02d:%02d', $sign, $h, $mm);
            }
        }
        (try DateTime.new("{$date}T$time$zone")) // Nil
    }

    # nushell's ranges: `1..3`, `1..<3`, `1..`, `..3`, and the stepped
    # `1..3..9`, which loads as the Seq `1, 3 ... 9`.
    method !range(Str:D $s) {
        my $num = / <[-+]>? [ \d+ [ '.' \d+ ]? | '.' \d+ ] [ <[eE]> <[-+]>? \d+ ]? /;
        my $m = $s.trim ~~ /^ ($num)? '..' [ ($num) '..' ]? ( '<' | '=' )? ($num)? $/;
        return Nil unless $m;
        my sub n($x) { $x.defined ?? (self!number($x.Str) // Nil) !! Nil }
        my $from = n($m[0]) // 0;
        my $next = n($m[1]);
        my $excl = $m[2].defined && $m[2].Str eq '<';
        my $to   = n($m[3]);
        if $next.defined {
            my $step = $next - $from;
            return Nil unless $step;
            return $to.defined
              ?? ($excl ?? ($from, $next ...^ $to) !! ($from, $next ... $to))
              !! ($from, $next ... *);
        }
        $to.defined
          ?? ($excl ?? $from ..^ $to !! $from .. $to)
          !! $from .. *
    }

    my constant B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    method !base64(Str:D $s) {
        my str $t = $s.subst(/\s+/, '', :g);
        return Nil unless $t ~~ /^ <[A..Za..z0..9+/]>* '='**0..2 $/ && nqp::chars($t) %% 4;
        my @bytes;
        my int $bits = 0;
        my int $acc = 0;
        for $t.comb -> $c {
            last if $c eq '=';
            $acc = ($acc +< 6) +| B64.index($c);
            $bits = $bits + 6;
            if $bits >= 8 {
                $bits = $bits - 8;
                @bytes.push: ($acc +> $bits) +& 0xFF;
            }
        }
        blob8.new(@bytes)
    }

    # --- encoding -----------------------------------------------------------

    # nushell's style: block collections, a sequence under a key at the key's
    # indentation, multi-line strings as `|` blocks.
    method encode(\v, Str:D $target --> Str:D) {
        self!node-text(v, 0, $target) ~ "\n"
    }

    # Several documents, separated by `---`.
    method encode-stream(\docs, Str:D $target --> Str:D) {
        docs.map({ self.encode($_, $target) }).join("---\n")
    }

    method !encode-fail(Str:D $target, Str:D $reason) is hidden-from-backtrace {
        X::Rak::Format::Encode.new(:$target, :format<yaml>, :$reason).throw
    }

    # The pairs of a mapping, or Nil.
    method !pairs(Mu \v) {
        nqp::istype(v, Rakudo::Internals::RakJSONObject) ?? v.pairs.List
          !! nqp::istype(v, Pair)   ?? (v,)
          !! nqp::istype(v, Bag) || nqp::istype(v, Mix)
            ?? v.pairs.sort(*.key.Str).List
          !! nqp::istype(v, Setty)  ?? Nil
          !! nqp::istype(v, Map)
            ?? (nqp::istype(v, Hash::Ordered) ?? v.keys !! v.keys.sort).map({ $_ => v.AT-KEY($_) }).List
          !! Nil
    }

    # The items of a sequence, or Nil.
    method !items(Mu \v, Str:D $target) {
        if nqp::istype(v, Setty) {
            return v.keys.sort(*.Str).List;
        }
        if nqp::istype(v, Range) {
            return Nil if self!range-text(v);
            self!encode-fail($target, 'an infinite range has no YAML form')
              if v.is-lazy || v.infinite;
            return v.list;
        }
        if nqp::istype(v, Seq) {
            self!encode-fail($target, 'an infinite sequence has no YAML form') if v.is-lazy;
            return v.cache.List;
        }
        nqp::istype(v, List) ?? v.list !! Nil
    }

    # A numeric range as nushell writes it, or Nil.
    method !range-text(Range:D \r) {
        my \lo = r.min;
        my \hi = r.max;
        return Nil unless nqp::istype(lo, Real) && nqp::istype(hi, Real);
        return Nil if lo == -Inf;
        return Nil if r.excludes-min && !nqp::istype(lo, Int);
        my $from = r.excludes-min ?? lo + 1 !! lo;
        my sub end-text(\n) { nqp::istype(n, Int) ?? n.Str !! self!float-text(n) }
        hi == Inf
          ?? '!range ' ~ end-text($from) ~ '..'
          !! '!range ' ~ end-text($from) ~ (r.excludes-max ?? '..<' !! '..') ~ end-text(hi)
    }

    method !float-text(\n --> Str:D) {
        if nqp::istype(n, Rational) {
            my $d := n.denominator;
            if $d {
                my int $twos = 0;
                my int $fives = 0;
                while $d %% 2 { $d := $d div 2; ++$twos }
                while $d %% 5 { $d := $d div 5; ++$fives }
                return n.base(10, 1 max $twos max $fives) if $d == 1;
            }
        }
        my \f = n.Num;
        f.isNaN ?? '.nan' !! f == Inf ?? '.inf' !! f == -Inf ?? '-.inf'
          !! do {
               my str $s = f.Str;
               nqp::index($s, '.') >= 0 || nqp::index($s, 'e') >= 0 ?? $s !! "$s.0"
             }
    }

    # The text of a node at indentation $n; its first line is not indented.
    method !node-text(Mu \v, int $n, Str:D $target) {
        my str $in = nqp::x(' ', $n);
        if nqp::istype(v, Failure) { v.throw }
        my $scalar := self!scalar-text(v, $n, $target);
        return $scalar if $scalar.defined;
        with self!pairs(v) -> @pairs {
            return '{}' unless @pairs;
            return @pairs.map(-> $pair {
                my \val = $pair.value;
                self!key-text($pair.key) ~ ':' ~ do {
                    my $s := self!scalar-text(val, $n + 2, $target);
                    if $s.defined { ' ' ~ $s }
                    elsif (my $p := self!pairs(val)).defined && $p.elems {
                        "\n" ~ nqp::x(' ', $n + 2) ~ self!node-text(val, $n + 2, $target)
                    }
                    elsif (my $i := self!items(val, $target)).defined && $i.elems {
                        "\n" ~ $in ~ self!node-text(val, $n, $target)
                    }
                    else { ' ' ~ self!node-text(val, $n + 2, $target) }
                }
            }).join("\n" ~ $in);
        }
        with self!items(v, $target) -> @items {
            return '[]' unless @items;
            return @items.map({ '- ' ~ self!node-text($_, $n + 2, $target) }).join("\n" ~ $in);
        }
        self!encode-fail($target, "a value of type {v.^name} has no YAML form")
    }

    method !key-text(Mu \k) {
        self!string-text(nqp::isconcrete(k) ?? k.Str !! '', :key)
    }

    # A scalar's text, or Nil for a collection.
    method !scalar-text(Mu \v, int $n, Str:D $target) {
        nqp::not_i(nqp::isconcrete(v))                     ?? 'null'
          !! nqp::istype(v, Bool)                          ?? (v ?? 'true' !! 'false')
          !! nqp::istype(v, Rakudo::Internals::RakFilesize) ?? '!filesize ' ~ v.Int.Str
          !! nqp::istype(v, Int)                           ?? v.Str
          !! nqp::istype(v, Duration)                      ?? '!duration ' ~ (v.Rat * 1_000_000_000).round.Str
          !! nqp::istype(v, DateTime)                      ?? '!!timestamp ' ~ v.Str
          !! nqp::istype(v, Date)                          ?? '!!timestamp ' ~ DateTime.new(:date(v)).Str
          !! nqp::istype(v, Instant)                       ?? '!!timestamp ' ~ DateTime.new(v).Str
          !! nqp::istype(v, Rational) || nqp::istype(v, Num) ?? self!float-text(v)
          !! nqp::istype(v, Str)                           ?? self!string-text(v, :$n)
          !! nqp::istype(v, Blob)                          ?? '!!binary ' ~ self!base64-text(v)
          !! nqp::istype(v, Range) && self!range-text(v)   ?? self!range-text(v)
          !! Nil
    }

    # A string: plain when it reads back as the same string, a `|` block
    # when it has several lines, else double-quoted.
    method !string-text(Str:D $s, int :$n = 0, :$key) {
        if !$key && $s.contains("\n") && $s !~~ / <[\x00..\x08\x0B..\x1F\x7F]> / {
            my str $body = $s;
            my int $trailing = 0;
            while $body.ends-with("\n") {
                $body = $body.chop;
                ++$trailing;
            }
            my $first = $body.lines.first(* ne '') // '';
            my $spaced = $first.starts-with(' ') || $first.starts-with("\t");
            unless $body eq '' || $spaced && $n == 0 {
                my $chomp = $trailing == 0 ?? '-' !! $trailing == 1 ?? '' !! '+';
                my str $in = nqp::x(' ', $n);
                my @lines = $body.split("\n");
                @lines.push('') for 1 ..^ $trailing;
                return '|' ~ ($spaced ?? '2' !! '') ~ $chomp
                  ~ @lines.map({ "\n" ~ ($_ eq '' ?? '' !! $in ~ $_) }).join;
            }
        }
        self!plain-ok($s) ?? $s !! Rakudo::Internals::JSON.to-json($s)
    }

    method !plain-ok(Str:D $s) {
        return False if $s eq '';
        return False if self!number($s).defined;
        return False if $s eq any('~', 'null', 'Null', 'NULL', 'true', 'True', 'TRUE',
          'false', 'False', 'FALSE');
        return False if $s ~~ / <[\x00..\x1F\x7F\x85\x2028\x2029]> /;
        return False if $s ~~ /^ \s | \s $/;
        return False if $s ~~ /^ <[\[\]{},#&*!|>'"%@`]> /;
        return False if $s ~~ /^ <[-?:]> [ \s | $ ] /;
        return False if $s ~~ /^ '---' | ^ '...' /;
        return False if $s.contains(': ') || $s.contains(' #') || $s.ends-with(':');
        True
    }

    method !base64-text(Blob:D $b) {
        my @out;
        my @bytes = $b.list;
        for @bytes.rotor(3, :partial) -> @g {
            my int $v = (@g[0] +< 16) +| ((@g[1] // 0) +< 8) +| (@g[2] // 0);
            my @c = (18, 12, 6, 0).map({ B64.substr(($v +> $_) +& 63, 1) });
            @c[3] = '=' if @g < 3;
            @c[2] = '=' if @g < 2;
            @out.push: @c.join;
        }
        @out.join
    }
}

# `from-yaml`: the text piped in, decoded. With --ignore-tags, an unknown tag
# loads the untagged value.
sub RAK-FROM-YAML(Mu \v, :$ignore-tags) is implementation-detail {
    my $text = nqp::istype(v, Iterable) ?? v.join("\n") !! v.Str;
    Rakudo::Internals::RakYAML.decode($text, 'from-yaml', :$ignore-tags)
}

# vim: expandtab shiftwidth=4
