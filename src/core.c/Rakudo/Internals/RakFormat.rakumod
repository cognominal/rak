# Runtime support for rak redirection formats
# (docs/adr/0004-format-targets-write-the-value-when-nothing-is-printed.md).
#
# A redirection target's extension may select a format. For a target with a
# format, output redirection writes the statement's value, encoded, when the
# statement printed nothing; otherwise it writes what was printed. Writes to a
# target with a format replace the file only once the new content is complete.

my class X::Rak::Format is Exception {
    has Str $.target;
    has Str $.format;
    has Str $.reason;
    method message() { "$!target: $!reason" }
}

my class X::Rak::Format::Encode is X::Rak::Format {
    method message() { "$.target: cannot encode as $.format: $.reason" }
}

my class X::Rak::Format::Decode is X::Rak::Format {
    has Int $.line;
    has Int $.column;
    method message() {
        "$.target: invalid {$.format.uc} at line $!line, column $!column: $.reason"
    }
}

# A value piped to a command that reads no format able to carry it
# (rak-plans/features/command-catalog.md#choosing-a-format).
my class X::Rak::Pipe::Format is Exception {
    has Str $.name;
    has @.reads;
    has Str $.what;
    method message() {
        $!what eq 'lines'
          ?? "$!name reads only {@!reads.join(', ')}: it cannot be sent lines; "
               ~ "pipe them through to-text first"
          !! "$!name reads only {@!reads.join(', ')}: it cannot be sent a table "
               ~ "or other structured data; pipe it through table, to-yaml or "
               ~ "to-json first"
    }
}

# Load found content whose shape does not fit the left-hand side's sigil.
my class X::Rak::Format::Shape is X::Rak::Format {
    has Str $.name;
    has Str $.expected;
    has Str $.found;
    method message() {
        my $what := $.format ?? $.format.uc ~ ' ' ~ $!expected !! $!expected;
        "$.target: expected {self!a($what)} $what for $!name, "
          ~ "found {self!a($!found)} $!found"
    }
    method !a(Str:D $word) { nqp::index('aeiou', nqp::substr($word, 0, 1)) >= 0 ?? 'an' !! 'a' }
}

# A JSON object, or a rak hash read from text, whose keys keep the order they
# were written in (rak-plans/features/formatter.md). Only the formatter makes one.
my class Rakudo::Internals::RakJSONObject is implementation-detail {
    has @.pairs;
}

# A relaxed JSON decoder: on top of standard JSON it accepts unquoted
# (identifier) keys, single-quoted strings, trailing commas, a leading `+` on
# numbers, and `//` and `/* */` comments. Objects decode to Hash, arrays to
# Array, null to Any, whole numbers to Int, decimals to Rat, numbers with an
# exponent to Num.
my class Rakudo::Internals::RakJSONDecoder is implementation-detail {
    has str $!text;
    has int $!pos;
    has int $!end;
    has Str $!target;
    has Bool $!ordered;

    submethod BUILD(Str:D :$text, Str:D :$target, :$ordered) {
        $!text    = $text;
        $!end     = nqp::chars($text);
        $!target  = $target;
        $!ordered = ?$ordered;
    }

    method decode(Str:D $text, Str:D $target) {
        my $self := self.new(:$text, :$target);
        $self.document
    }

    # Concatenated JSON values, as in JSON Lines or `{"a":1}{"b":2}`. With
    # :ordered, objects keep their key order (RakJSONObject).
    method stream(Str:D $text, Str:D $target, :$ordered) {
        my $self := self.new(:$text, :$target, :$ordered);
        $self.documents
    }

    method documents() {
        my @docs;
        self!ws;
        while $!pos < $!end {
            @docs.push: self!value;
            self!ws;
        }
        @docs
    }

    method document() {
        self!ws;
        my \value = self!value;
        self!ws;
        self!fail('unexpected text after the value') if $!pos < $!end;
        value
    }

    method !fail(Str:D $reason) is hidden-from-backtrace {
        my int $line = 1;
        my int $start = 0;
        my int $i = 0;
        while $i < $!pos && $i < $!end {
            if nqp::eqat($!text, "\n", $i) {
                ++$line;
                $start = $i + 1;
            }
            ++$i;
        }
        X::Rak::Format::Decode.new(
          :$!target, :format<json>, :$reason,
          :line($line), :column($!pos - $start + 1)
        ).throw
    }

    method !char() { nqp::substr($!text, $!pos, 1) }

    method !ws() {
        while $!pos < $!end {
            my str $c = nqp::substr($!text, $!pos, 1);
            if $c eq ' ' || $c eq "\t" || $c eq "\n" || $c eq "\r" {
                ++$!pos;
            }
            elsif nqp::eqat($!text, '//', $!pos) {
                $!pos = $!pos + 2;
                ++$!pos while $!pos < $!end && !nqp::eqat($!text, "\n", $!pos);
            }
            elsif nqp::eqat($!text, '/*', $!pos) {
                my int $close = nqp::index($!text, '*/', $!pos + 2);
                self!fail('unterminated comment') if $close < 0;
                $!pos = $close + 2;
            }
            else {
                last;
            }
        }
    }

    method !value() {
        self!fail('unexpected end of input') if $!pos >= $!end;
        my str $c = self!char;
        if    $c eq '{'               { self!object }
        elsif $c eq '['               { self!array  }
        elsif $c eq '"' || $c eq "'"  { self!string }
        elsif nqp::eqat($!text, 'true',  $!pos) { $!pos = $!pos + 4; True  }
        elsif nqp::eqat($!text, 'false', $!pos) { $!pos = $!pos + 5; False }
        elsif nqp::eqat($!text, 'null',  $!pos) { $!pos = $!pos + 4; Any   }
        elsif nqp::index('+-0123456789.', $c) >= 0 { self!number }
        else  { self!fail("unexpected '$c'") }
    }

    method !object() {
        ++$!pos;    # {
        my %h;
        my @pairs;
        self!ws;
        until $!pos < $!end && self!char eq '}' {
            my str $key = self!key;
            self!ws;
            self!fail("expected ':' after a key")
              unless $!pos < $!end && self!char eq ':';
            ++$!pos;
            self!ws;
            $!ordered
              ?? @pairs.push(Pair.new($key, self!value))
              !! (%h{$key} = self!value);
            self!ws;
            self!fail('unexpected end of input, expected \'}\'') if $!pos >= $!end;
            if self!char eq ',' {
                ++$!pos;
                self!ws;
            }
            elsif self!char ne '}' {
                self!fail("expected ',' or '}'");
            }
        }
        ++$!pos;    # }
        $!ordered ?? Rakudo::Internals::RakJSONObject.new(:@pairs) !! %h
    }

    method !key() {
        self!fail('unexpected end of input, expected a key') if $!pos >= $!end;
        my str $c = self!char;
        return self!string if $c eq '"' || $c eq "'";
        my int $start = $!pos;
        while $!pos < $!end {
            my int $o = nqp::ord($!text, $!pos);
            last unless $o == 95 || $o == 36                 # _ $
              || (65 <= $o <= 90) || (97 <= $o <= 122)       # A-Z a-z
              || ($!pos > $start && 48 <= $o <= 57);         # 0-9
            ++$!pos;
        }
        self!fail("expected a key, found '$c'") if $!pos == $start;
        nqp::substr($!text, $start, $!pos - $start)
    }

    method !array() {
        ++$!pos;    # [
        my @a;
        self!ws;
        until $!pos < $!end && self!char eq ']' {
            @a.push: self!value;
            self!ws;
            self!fail('unexpected end of input, expected \']\'') if $!pos >= $!end;
            if self!char eq ',' {
                ++$!pos;
                self!ws;
            }
            elsif self!char ne ']' {
                self!fail("expected ',' or ']'");
            }
        }
        ++$!pos;    # ]
        @a
    }

    method !string() {
        my str $quote = self!char;
        ++$!pos;
        my $parts := nqp::list_s;
        loop {
            self!fail('unterminated string') if $!pos >= $!end;
            my str $c = self!char;
            if $c eq $quote {
                ++$!pos;
                last;
            }
            elsif $c eq "\n" {
                self!fail('newline in string');
            }
            elsif $c eq '\\' {
                ++$!pos;
                self!fail('unterminated string') if $!pos >= $!end;
                my str $e = self!char;
                ++$!pos;
                if    $e eq 'n' { nqp::push_s($parts, "\n") }
                elsif $e eq 't' { nqp::push_s($parts, "\t") }
                elsif $e eq 'r' { nqp::push_s($parts, "\r") }
                elsif $e eq 'b' { nqp::push_s($parts, "\b") }
                elsif $e eq 'f' { nqp::push_s($parts, "\f") }
                elsif $e eq 'u' { nqp::push_s($parts, self!unicode) }
                elsif nqp::index('"\\\'/', $e) >= 0 { nqp::push_s($parts, $e) }
                else {
                    --$!pos;
                    self!fail("unknown escape '\\$e'");
                }
            }
            else {
                nqp::push_s($parts, $c);
                ++$!pos;
            }
        }
        nqp::join('', $parts)
    }

    method !hex4() {
        my str $hex = nqp::substr($!text, $!pos, 4);
        self!fail('expected 4 hex digits after \\u')
          unless nqp::chars($hex) == 4 && $hex ~~ /^ <[0..9a..fA..F]>**4 $/;
        $!pos = $!pos + 4;
        :16($hex)
    }

    method !unicode() {
        my int $cp = self!hex4;
        if 0xD800 <= $cp <= 0xDBFF && nqp::eqat($!text, '\\u', $!pos) {
            $!pos = $!pos + 2;
            my int $low = self!hex4;
            $cp = 0x10000 + (($cp - 0xD800) +< 10) + ($low - 0xDC00);
        }
        nqp::chr($cp)
    }

    method !number() {
        my int $start = $!pos;
        ++$!pos if self!char eq '+' || self!char eq '-';
        my int $digits = $!pos;
        ++$!pos while $!pos < $!end && 48 <= nqp::ord($!text, $!pos) <= 57;
        my int $int-digits = $!pos - $digits;
        my int $frac = 0;
        my int $exp = 0;
        if $!pos < $!end && self!char eq '.' {
            ++$!pos;
            my int $f = $!pos;
            ++$!pos while $!pos < $!end && 48 <= nqp::ord($!text, $!pos) <= 57;
            $frac = $!pos - $f;
            unless $frac || $int-digits {
                $!pos = $start;
                self!fail('malformed number');
            }
        }
        if $!pos < $!end && (self!char eq 'e' || self!char eq 'E') {
            ++$!pos;
            ++$!pos if $!pos < $!end && (self!char eq '+' || self!char eq '-');
            my int $e = $!pos;
            ++$!pos while $!pos < $!end && 48 <= nqp::ord($!text, $!pos) <= 57;
            $exp = 1;
            if $!pos == $e {
                $!pos = $start;
                self!fail('malformed number');
            }
        }
        unless $int-digits || $frac {
            $!pos = $start;
            self!fail('malformed number');
        }
        my str $n = nqp::substr($!text, $start, $!pos - $start);
        $n = nqp::substr($n, 1) if nqp::eqat($n, '+', 0);
        $n = nqp::concat($n, '0') if nqp::eqat($n, '.', nqp::chars($n) - 1);
        $exp ?? $n.Num !! $frac ?? $n.Rat !! $n.Int
    }
}

# An output handle that keeps what is printed to it in memory.
my class Rakudo::Internals::RakCapture is IO::Handle is implementation-detail {
    has $!bytes = buf8.new;
    submethod TWEAK() { self.encoding: 'utf8' }
    method WRITE(Blob:D \data --> True) { $!bytes.append: data }
    method opened(--> True) { }
    method close(--> True) { }
    method printed() { $!bytes.elems > 0 }
    method text() { $!bytes.decode('utf8') }
}

my class Rakudo::Internals::RakYAML { ... }
my class Rakudo::Internals::RakCatalog { ... }

my class Rakudo::Internals::RakFormat is implementation-detail {

    # The format a target's extension selects, ignoring case, or Nil. A
    # `.yml` target is a `.yaml` one.
    method of(Str:D $target) {
        my str $lc = nqp::lc($target);
        my sub ends(str $ext) {
            nqp::chars($lc) > nqp::chars($ext)
              && nqp::eqat($lc, $ext, nqp::chars($lc) - nqp::chars($ext))
        }
        ends('.json') ?? 'json'
          !! ends('.jsonl') ?? 'jsonl'
          !! ends('.yaml') || ends('.yml') ?? 'yaml'
          !! Nil
    }

    # JSON is written pretty. JSON Lines is one compact record per line: an
    # array (or other list) is one record per element, anything else is one
    # record.
    method encode(Str:D $format, \value, Str:D $target --> Str:D) {
        if $format eq 'yaml' {
            Rakudo::Internals::RakYAML.encode(
              nqp::istype(value, Failure) ?? value.throw !! value, $target)
        }
        elsif $format eq 'jsonl' {
            my \v = nqp::istype(value, Failure) ?? value.throw !! value;
            nqp::isconcrete(v) && !nqp::istype(v, Map)
              && (nqp::istype(v, List) || nqp::istype(v, Seq) || nqp::istype(v, Range))
              ?? v.list.map({ self!json($_, $target, 0, :compact) ~ "\n" }).join
              !! self!json(v, $target, 0, :compact) ~ "\n"
        }
        else {
            self!json(value, $target, 0) ~ "\n"
        }
    }

    # JSON Lines decodes to the array of records; blank lines are skipped. A
    # record holds no newline, so a decode error's line is the file's line.
    method decode(Str:D $format, Str:D $text, Str:D $target) {
        if $format eq 'yaml' {
            Rakudo::Internals::RakYAML.decode($text, $target)
        }
        elsif $format eq 'jsonl' {
            my @records;
            my int $line = 0;
            for $text.lines -> $record {
                ++$line;
                next unless $record.trim;
                @records.push: Rakudo::Internals::RakJSONDecoder.decode($record, $target);
                CATCH {
                    when X::Rak::Format::Decode {
                        X::Rak::Format::Decode.new(
                          :$target, :format<jsonl>, :reason(.reason),
                          :$line, :column(.column)
                        ).throw
                    }
                }
            }
            @records
        }
        else {
            Rakudo::Internals::RakJSONDecoder.decode($text, $target)
        }
    }

    method !fail(Str:D $target, Str:D $reason) is hidden-from-backtrace {
        X::Rak::Format::Encode.new(:$target, :format<json>, :$reason).throw
    }

    # A Rat whose denominator has no prime factor but 2 and 5 has an exact
    # decimal form; anything else is written as a floating-point number.
    method !rational(\r, Str:D $target --> Str:D) {
        my $d := r.denominator;
        return self!num(r.Num, $target) unless $d;
        my int $twos  = 0;
        my int $fives = 0;
        while $d %% 2 { $d := $d div 2; ++$twos  }
        while $d %% 5 { $d := $d div 5; ++$fives }
        $d == 1
          ?? r.base(10, $twos max $fives)
          !! self!num(r.Num, $target)
    }

    method !num(Num:D \n, Str:D $target --> Str:D) {
        n.isNaN || n == Inf || n == -Inf
          ?? self!fail($target, "{n} has no JSON form")
          !! n.Str
    }

    # The formatter's JSON (rak-plans/features/formatter.md): pretty, and with
    # :color, in jq's default colors.
    method format(\v, :$color --> Str:D) {
        self!json(v, 'formatter', 0, :color(?$color))
    }

    method !json(\v, Str:D $target, int $level, Bool :$compact, Bool :$color --> Str:D) {
        my str $in  = $compact ?? '' !! nqp::x('  ', $level + 1);
        my str $out = $compact ?? '' !! nqp::x('  ', $level);
        my str $nl  = $compact ?? '' !! "\n";
        my str $sep = $compact ?? ',' !! ",\n";
        my str $col = $compact ?? ':' !! ': ';
        # jq's default colors: null gray, strings green, keys bold blue,
        # brackets bold.
        my sub c(str $code, str $text) {
            $color ?? "\e[{$code}m$text\e[0m" !! $text
        }
        my sub object(@pairs) {
            @pairs
              ?? c('1;39', '{') ~ $nl ~ @pairs.map({
                     $in ~ c('34;1', Rakudo::Internals::JSON.to-json(.key.Str)) ~ $col
                       ~ self!json(.value, $target, $level + 1, :$compact, :$color)
                 }).join($sep) ~ $nl ~ $out ~ c('1;39', '}')
              !! c('1;39', '{}')
        }
        if nqp::istype(v, Failure) {
            v.throw
        }
        elsif nqp::not_i(nqp::isconcrete(v)) {
            c('90', 'null')
        }
        elsif nqp::istype(v, Bool) {
            v ?? 'true' !! 'false'
        }
        elsif nqp::istype(v, Str) {
            c('0;32', Rakudo::Internals::JSON.to-json(v))
        }
        elsif nqp::istype(v, Rakudo::Internals::RakJSONObject) {
            object(v.pairs)
        }
        elsif nqp::istype(v, Int) {
            v.Str
        }
        # nushell's `to json`: a duration in nanoseconds, a date in RFC 3339.
        elsif nqp::istype(v, Duration) {
            (v.Rat * 1_000_000_000).round.Str
        }
        elsif nqp::istype(v, DateTime) {
            c('0;32', Rakudo::Internals::JSON.to-json(v.Str))
        }
        elsif nqp::istype(v, Instant) {
            c('0;32', Rakudo::Internals::JSON.to-json(DateTime.new(v).Str))
        }
        elsif nqp::istype(v, Rational) {
            self!rational(v, $target)
        }
        elsif nqp::istype(v, Num) {
            self!num(v, $target)
        }
        elsif nqp::istype(v, Map) {
            object((nqp::istype(v, Hash::Ordered) ?? v.keys !! v.keys.sort)
              .map({ $_ => v.AT-KEY($_) }))
        }
        elsif nqp::istype(v, List) || nqp::istype(v, Seq) || nqp::istype(v, Range) {
            my @items = v.list;
            @items
              ?? c('1;39', '[') ~ $nl ~ @items.map({
                     $in ~ self!json($_, $target, $level + 1, :$compact, :$color)
                 }).join($sep) ~ $nl ~ $out ~ c('1;39', ']')
              !! c('1;39', '[]')
        }
        else {
            self!fail($target, "a value of type {v.^name} has no JSON form")
        }
    }

    # Replace the target with $content only once it is completely written.
    method write(Str:D $target, Str:D $content --> True) {
        my $tmp := "$target.rak-tmp-$*PID";
        my $written := $tmp.IO.spurt($content);
        $written.throw if nqp::istype($written, Failure);
        my $moved := $tmp.IO.rename($target);
        if nqp::istype($moved, Failure) {
            $tmp.IO.unlink;
            $moved.throw;
        }
    }
}

# Rak data literals read from text, for the formatter
# (rak-plans/features/formatter.md): numbers, quoted strings, True, False, Nil,
# naked strings, pairs, word lists, and ( ), [ ], { }. The text is parsed,
# never run: anything else is not data, and `read` returns the
# RakDataReader type object.
my class Rakudo::Internals::RakDataReader is implementation-detail {
    has str $!text;
    has int $!pos;
    has int $!end;

    my class NotData is Exception { }

    method read(Str:D $text) {
        my $self := self.bless;
        nqp::bindattr_s($self, Rakudo::Internals::RakDataReader, '$!text', $text);
        nqp::bindattr_i($self, Rakudo::Internals::RakDataReader, '$!end', nqp::chars($text));
        my $result := try $self!document;
        $! ?? self !! $result
    }

    method !no() is hidden-from-backtrace { NotData.new.throw }

    method !ws() {
        ++$!pos while $!pos < $!end
          && nqp::iscclass(nqp::const::CCLASS_WHITESPACE, $!text, $!pos);
    }

    method !at(Str:D $s) { nqp::eqat($!text, $s, $!pos) }

    method !match(Regex:D $re) {
        my $m := $!text.match($re, :p($!pos));
        return Nil unless $m;
        $!pos = $m.to;
        ~$m
    }

    method !document() {
        my @items = self!items('');
        self!no if $!pos < $!end;
        @items == 1 ?? @items[0] !! @items.List
    }

    # Comma-separated items up to $close (or the end, for '').
    method !items(Str:D $close) {
        my @items;
        self!ws;
        until $close ?? self!at($close) !! $!pos >= $!end {
            @items.push: self!item;
            self!ws;
            if self!at(',') {
                ++$!pos;
                self!ws;
            }
            elsif !($close ?? self!at($close) !! $!pos >= $!end) {
                self!no;
            }
        }
        $!pos = $!pos + nqp::chars($close);
        @items
    }

    method !item() {
        self!no if $!pos >= $!end;
        my $v := self!value;
        self!ws;
        if self!at('=>') {
            $!pos = $!pos + 2;
            self!ws;
            self!no if nqp::istype($v, Pair) || nqp::istype($v, Positional)
              || nqp::istype($v, Rakudo::Internals::RakJSONObject);
            return Pair.new($v, self!value);
        }
        $v
    }

    method !value() {
        self!no if $!pos >= $!end;
        if self!at(':') {
            ++$!pos;
            my $neg := self!at('!') ?? (++$!pos; True) !! False;
            my $name := self!match(/ <.ident> [ <[\-']> <.ident> ]* /) // self!no;
            return Pair.new($name, False) if $neg;
            if self!at('(') {             # :name(value), :name(a, b)
                ++$!pos;
                my @i = self!items(')');
                return Pair.new($name, @i == 1 ?? @i[0] !! @i.List);
            }
            return Pair.new($name, self!value)
              if self!at('[') || self!at('{') || self!at('<');
            return Pair.new($name, True);
        }
        if self!at('(') { ++$!pos; my @i = self!items(')'); return @i.List }
        if self!at('[') { ++$!pos; my @i = self!items(']'); return @i }
        if self!at('{') {
            ++$!pos;
            my @i = self!items('}');
            self!no if @i.grep({ nqp::not_i(nqp::istype($_, Pair)) });
            return Rakudo::Internals::RakJSONObject.new(:pairs(@i));
        }
        if self!at('<') {
            my $words := self!match(/ '<' <-[>]>* '>' /) // self!no;
            my @w = $words.substr(1, *-1).words;
            return @w == 1 ?? @w[0] !! @w.List;
        }
        if self!at("'") {
            my $s := self!match(/ "'" [ <-['\\]> | '\\' . ]* "'" /) // self!no;
            return $s.substr(1, *-1).subst(/ '\\' (<['\\]>) /, { ~$0 }, :g);
        }
        if self!at('"') {
            my $s := self!match(/ '"' [ <-["\\$@{]> | '\\' <[nt"\\]> ]* '"' /) // self!no;
            return $s.substr(1, *-1).subst(/ '\\' (.) /,
              { (n => "\n", t => "\t").Hash{~$0} // ~$0 }, :g);
        }
        with self!match(/ '-'? \d+ [ '_' \d+ ]* [ '.' \d+ ]? [ <[eE]> <[+-]>? \d+ ]? <!before <[\w]>> /) -> $n {
            my $clean := $n.subst('_', '', :g);
            return $clean ~~ /<[eE]>/ ?? $clean.Num
              !! $clean.contains('.') ?? $clean.Rat !! $clean.Int;
        }
        with self!match(/ <.ident> [ <[\-']> <.ident> ]* /) -> $word {
            return $word eq 'True' ?? True
              !! $word eq 'False' ?? False
              !! $word eq 'Nil' ?? Nil
              !! $word;
        }
        self!no
    }
}

# The formatter's value (rak-plans/features/formatter.md): the JSON text of its
# documents. Sunk at statement level, it prints them instead, in color on a
# terminal; irak shows it the same way and leaves $_ alone.
my class Rakudo::Internals::RakFormatted is Str is implementation-detail {
    has $!docs;

    method from-docs(\docs) {
        my $text := docs.map({ Rakudo::Internals::RakFormat.format($_) }).join("\n");
        my $self := nqp::box_s(nqp::unbox_s($text), self);
        nqp::bindattr($self, Rakudo::Internals::RakFormatted, '$!docs', docs.List);
        $self
    }

    method show(--> Nil) {
        my $out := $*OUT;
        my $color := ?(try $out.t);
        $out.print: $!docs.map({
            Rakudo::Internals::RakFormat.format($_, :$color) ~ "\n"
        }).join;
    }

    method sink(--> Nil) { self.show }

    # The text alone, as a plain Str.
    method plain() { nqp::box_s(nqp::unbox_s(self), Str) }
}

# URL targets (rak-plans/features/url-targets.md): a load from an http(s) URL is a
# GET, output redirection to one is a POST of JSON. Every request goes through
# RakHTTP.request, which runs curl, or HTTP::UserAgent when curl is missing.
my class X::Rak::HTTP is Exception {
    has Str $.url;
    has $.status;                 # an Int, or Nil when no response came back
    has Str $.reason;
    method message() {
        $!status.defined ?? "$!url: HTTP $!status: $!reason" !! "$!url: $!reason"
    }
}

my int $RAK-HTTP-SEQ;

# irak's web log (@*IWEB): while on, each request is kept here until the
# REPL takes it, at the end of the submission, and adds what only it knows.
my $RAK-WEB-ON;
my $RAK-WEB := IterationBuffer.new;
sub RAK-WEB-ON(--> Nil) is implementation-detail { $RAK-WEB-ON := True }
sub RAK-WEB-TAKE() is implementation-detail {
    my $taken := $RAK-WEB.List;
    $RAK-WEB := IterationBuffer.new;
    $taken
}

my class Rakudo::Internals::RakHTTP is implementation-detail {

    method is-url(Str:D $target) {
        my str $lc = nqp::lc($target);
        nqp::eqat($lc, 'http://', 0) || nqp::eqat($lc, 'https://', 0)
    }

    # A JSON media type: application/json, or any +json one.
    method is-json(Str:D $type) {
        my $mt := nqp::lc($type.split(';')[0].trim);
        $mt eq 'application/json' || $mt.ends-with('+json')
    }

    # A YAML media type (rak-plans/features/yaml.md).
    method is-yaml(Str:D $type) {
        my $mt := nqp::lc($type.split(';')[0].trim);
        $mt eq 'application/yaml' || $mt eq 'application/x-yaml' || $mt eq 'text/yaml'
          || $mt.ends-with('+yaml')
    }

    # The format a response's media type selects, or Nil.
    method format-of(Str:D $type) {
        self.is-json($type) ?? 'json' !! self.is-yaml($type) ?? 'yaml' !! Nil
    }

    method which(Str:D $name) {
        $*SPEC.path.map({ .IO.add($name) }).first({ .f && .x })
    }

    # The URL's host:port and host.
    method authority(Str:D $url) {
        my $rest := $url.substr($url.index('://') + 3);
        my $end  := $rest.chars;
        for '/', '?', '#' { with $rest.index($_) { $end := $_ if $_ < $end } }
        my $auth := $rest.substr(0, $end);
        $auth := $auth.substr($auth.rindex('@') + 1) if $auth.contains('@');
        ($auth, $auth.contains(':') ?? $auth.substr(0, $auth.rindex(':')) !! $auth)
    }

    method config-file() {
        RAK-XDG-DIR('config').add('http-headers.json')
    }

    # The headers for a URL: rak's user agent, then those the config file
    # gives its host (host:port first). A value `$NAME` is that environment
    # variable, and the header is left out when it is unset; `auth: TOKEN` is
    # `Authorization: Bearer TOKEN`. With no authorization configured,
    # api.github.com gets the token of `gh auth token`.
    method headers(Str:D $url) {
        my ($auth, $host) = self.authority($url);
        my @headers = 'User-Agent' => 'rak';
        my %config;
        my $file := self.config-file;
        if $file.e {
            my $c := Rakudo::Internals::RakFormat.decode('json', $file.slurp, ~$file);
            my $for := nqp::istype($c, Map) ?? ($c{$auth} // $c{$host}) !! Nil;
            X::Rak::Format.new(:target(~$file), :format<json>,
              :reason("expected an object of headers for each host")
            ).throw unless nqp::istype($c, Map) && (!$for.defined || nqp::istype($for, Map));
            %config = $for if $for.defined;
        }
        my $has-auth := False;
        for %config.sort(*.key) -> (:key($name), :value($raw)) {
            my $value := ~$raw;
            if $value.starts-with('$') {
                $value := %*ENV{$value.substr(1)} // next;
            }
            if nqp::lc($name) eq 'auth' {
                @headers.push: 'Authorization' => "Bearer $value";
                $has-auth := True;
            }
            else {
                $has-auth := True if nqp::lc($name) eq 'authorization';
                @headers.push: $name => $value;
            }
        }
        if !$has-auth && $host eq 'api.github.com' {
            with self!gh-token -> $token {
                @headers.push: 'Authorization' => "Bearer $token";
            }
        }
        @headers
    }

    method !gh-token() {
        self.which('gh') or return Nil;
        my $proc := Proc.new(:out, :err);
        $proc.spawn('gh', 'auth', 'token');
        my $token := $proc.out.slurp(:close).trim;
        $proc.err.slurp(:close);
        $proc.exitcode == 0 && $token ?? $token !! Nil
    }

    # The response (status, media type, body). A failed connection or an
    # error status throws X::Rak::HTTP.
    method request(Str:D $method, Str:D $url, Str $body?) {
        my @headers = self.headers($url);
        @headers.push: 'Content-Type' => 'application/json' if $body.defined;
        my %out;
        my ($status, $type, $content);
        {
            CATCH {
                default {
                    self!log($method, $url, @headers, %out, $status, $type, $content)
                      if $RAK-WEB-ON;
                    .rethrow
                }
            }
            ($status, $type, $content) = self.which('curl')
              ?? self!curl($url, @headers, $body, %out)
              !! self!user-agent($method, $url, @headers, $body, %out);
            X::Rak::HTTP.new(:$url, :$status, :reason(self!reason($type, $content, $status))).throw
              if $status >= 400;
        }
        self!log($method, $url, @headers, %out, $status, $type, $content) if $RAK-WEB-ON;
        ($status, $type, $content)
    }

    # A header that may carry a secret, hidden in the web log.
    method !secret(Str:D $name) {
        my $lc := $name.lc;
        $lc eq 'authorization' | 'proxy-authorization' | 'cookie' | 'set-cookie'
          || $lc.contains('token') || $lc.contains('key') || $lc.contains('secret')
    }

    method !log($method, $url, @in, %out, $status, $type, $content --> Nil) {
        my %in;
        for @in { %in{.key} = self!secret(.key) ?? '***' !! ~.value }
        my %o = %out.map({ .key => (self!secret(.key) ?? '***' !! .value) });
        my $body := $type.defined && $content.defined
          ?? (try self.value($url, $type, $content)) // $content
          !! Nil;
        $RAK-WEB.push: {
          :$url, :$method, :status($status // Int), :%in, :out(%o), :$body
        };
    }

    # The server's message: a JSON body's `message`, else the first line.
    method !reason(Str:D $type, Str:D $content, $status) {
        if self.is-json($type) {
            my $v := try Rakudo::Internals::RakFormat.decode('json', $content, 'response');
            return ~$v<message> if nqp::istype($v, Map) && $v<message>.defined;
        }
        $content.lines.first(*.trim) // "no message"
    }

    # The decoded value of a response body: JSON by its media type, else the
    # text; Nil for an empty body.
    method value(Str:D $url, Str:D $type, Str:D $content) {
        my $format := self.format-of($type);
        $content.chars == 0 ?? Nil
          !! $format        ?? Rakudo::Internals::RakFormat.decode($format, $content, $url)
          !! $content
    }

    method post(Str:D $url, Str:D $body) {
        my ($, $type, $content) = self.request('POST', $url, $body);
        self.value($url, $type, $content)
    }

    # curl reads its options from standard input, so the URL and the
    # headers (tokens) never appear in a process listing.
    method !curl(Str:D $url, @headers, $body, %out) {
        sub q(Str() $s) {
            '"' ~ $s.subst('\\', '\\\\', :g).subst('"', '\\"', :g)
                    .subst("\n", '\\n', :g).subst("\r", '\\r', :g) ~ '"'
        }
        my $seq  := ++$RAK-HTTP-SEQ;
        my $out  := $*TMPDIR.add("rak-http-$*PID-$seq.out");
        my $in   := $*TMPDIR.add("rak-http-$*PID-$seq.in");
        my $hdr  := $*TMPDIR.add("rak-http-$*PID-$seq.hdr");
        LEAVE { .unlink if .e for $out, $in, $hdr }
        my @config = "url = {q $url}", "output = {q $out}",
          "dump-header = {q $hdr}",
          'silent', 'show-error', 'location',
          'write-out = "%{http_code}\n%{content_type}"';
        @config.push: "header = {q "{.key}: {.value}"}" for @headers;
        if $body.defined {
            $in.spurt($body);
            @config.push: "data-binary = {q '@' ~ $in}";
        }
        my $proc := Proc.new(:in, :out, :err);
        $proc.spawn('curl', '--config', '-');
        $proc.in.print(@config.join("\n") ~ "\n");
        # Closing the input pipe returns the Proc: sunk, it would throw
        # X::Proc::Unsuccessful before the exit code is looked at.
        my $closed := $proc.in.close;
        my $meta := $proc.out.slurp(:close);
        my $err  := $proc.err.slurp(:close).trim;
        if $proc.exitcode -> $code {
            $err := $err.substr($err.index(') ') + 2)
              if $err.starts-with('curl: (') && $err.contains(') ');
            X::Rak::HTTP.new(:$url, :reason($err || "curl failed with exit code $code")).throw;
        }
        # The headers of the last response: a redirect dumps one block each.
        if $hdr.e {
            my @block;
            for $hdr.slurp.lines {
                if .starts-with('HTTP/') { @block = () }
                elsif .contains(':') { @block.push: .substr(0, .index(':')) => .substr(.index(':') + 1).trim }
            }
            for @block { %out{.key} = %out{.key}:exists ?? "%out{.key}, {.value}" !! .value }
        }
        my @meta = $meta.lines;
        (@meta[0].Int, @meta[1] // '', $out.e ?? $out.slurp !! '')
    }

    # Without curl: HTTP::UserAgent, if it is installed.
    method !user-agent(Str:D $method, Str:D $url, @headers, $body, %out) {
        sub need(Str:D $name) {
            my $unit := $*REPO.need(CompUnit::DependencySpecification.new(:short-name($name)));
            $unit.handle.globalish-package.AT-KEY('HTTP').WHO.AT-KEY($name.substr(6))
        }
        my \UA = try need('HTTP::UserAgent');
        X::Rak::HTTP.new(:$url,
          :reason('a URL target needs curl on $PATH, or the HTTP::UserAgent module')
        ).throw unless UA.^name eq 'HTTP::UserAgent';
        my \Request = need('HTTP::Request');
        my $req := Request.new(|($method => $url));
        $req.header.field(|%(@headers));
        $req.add-content($body) if $body.defined;
        my $res := try UA.new(:useragent<rak>, :!throw-exceptions).request($req);
        X::Rak::HTTP.new(:$url, :reason(~($! // 'no response'))).throw unless $res.defined;
        for $res.header.hash.kv -> $name, $value { %out{$name} = $value.join(', ') }
        ($res.code.Int, ~($res.content-type // ''), ~($res.decoded-content // ''))
    }
}

# Output redirection, `STMT >target` / `STMT >>target`: run the thunked
# statement with $*OUT bound to the target for that statement alone. A target
# with a format is written whole, from the printed text or, if nothing was
# printed, from the encoded value.
sub RAK-REDIRECT-OUT(Str() $target, Str:D $mode, &code, $?) is implementation-detail {
    # The optional last argument is a declaration hoisted out of the
    # statement (Rak::Actions.hoist-declaration); only its effect matters.
    # A URL target: the statement's output is POSTed as JSON, and its value
    # is the response (docs/adr/0005-a-url-target-gives-the-response-as-the-statement-value.md).
    if Rakudo::Internals::RakHTTP.is-url($target) {
        X::Rak::HTTP.new(:url($target),
          :reason('cannot append to a URL target, use >url to POST')
        ).throw if $mode eq 'a';
        my $capture := Rakudo::Internals::RakCapture.new;
        my \result = do {
            my $*OUT := $capture;
            my \r = RAK-REDIRECT-FORMATTED(code());
            nqp::istype(r, Seq) ?? r.eager !! r
        };
        return Rakudo::Internals::RakHTTP.post: $target,
          Rakudo::Internals::RakFormat.encode('json',
            $capture.printed
              ?? Rakudo::Internals::RakFormat.decode('json', $capture.text, $target)
              !! result,
            $target);
    }
    my $format := Rakudo::Internals::RakFormat.of($target);
    if $format {
        X::Rak::Format.new(:$target, :$format,
          :reason("cannot append to a .json target, use .jsonl for one record per line")
        ).throw if $mode eq 'a' && $format eq 'json';

        my $capture := Rakudo::Internals::RakCapture.new;
        my \result = do {
            my $*OUT := $capture;
            my \r = RAK-REDIRECT-FORMATTED(code());
            nqp::istype(r, Seq) ?? r.eager !! r
        };
        # Text mode: what was printed must decode in the format, and is
        # written re-encoded in standard form. Value mode: the value is.
        my $content := Rakudo::Internals::RakFormat.encode($format,
            $capture.printed
              ?? Rakudo::Internals::RakFormat.decode($format, $capture.text, $target)
              !! result,
            $target);
        if $mode eq 'a' {
            # Appending JSON Lines: the records are complete before any is
            # written, so a failure leaves the file as it was. Appending YAML
            # adds a document.
            $content := "---\n" ~ $content
              if $format eq 'yaml' && $target.IO.e && $target.IO.s;
            my $fh := open($target, :a);
            $fh.throw if nqp::istype($fh, Failure);
            $fh.print($content);
            $fh.close;
        }
        else {
            Rakudo::Internals::RakFormat.write: $target, $content;
        }
        result
    }
    else {
        my $fh := open($target, |($mode eq 'a' ?? (:a) !! (:w)));
        $fh.throw if nqp::istype($fh, Failure);
        my $*OUT := $fh;
        LEAVE $fh.close;
        my \result = RAK-REDIRECT-FORMATTED(code());
        nqp::istype(result, Seq) ?? result.eager !! result
    }
}

# The last value a load decoded from JSON. irak shows a submission whose value
# it is the way the formatter does (rak-plans/features/formatter.md).
my $RAK-LOADED;
sub RAK-LOADED() is raw is implementation-detail { $RAK-LOADED }

# Load, `LVALUE <target`: the target's content, for assignment to LVALUE. A
# target with a format is decoded and must have the shape the sigil asks for
# (@ an array, % an object, ~ a string, # an integer, $ anything). A target
# without one loads as lines for @, as the whole text otherwise.
sub RAK-LOAD(Str() $target, Str:D $sigil, Str:D $name) is raw is implementation-detail {
    my $format;
    my $text;
    if Rakudo::Internals::RakHTTP.is-url($target) {
        my ($, $type, $content) = Rakudo::Internals::RakHTTP.request('GET', $target);
        $format = Rakudo::Internals::RakHTTP.format-of($type);
        $text   = $content;
    }
    else {
        $format = Rakudo::Internals::RakFormat.of($target);
        $text   = $target.IO.slurp;
        $text.throw if nqp::istype($text, Failure);
    }

    sub shape(\v) {
        nqp::istype(v, Failure)                ?? 'failure'
          !! nqp::not_i(nqp::isconcrete(v))    ?? 'null'
          !! nqp::istype(v, Bool)              ?? 'boolean'
          !! nqp::istype(v, Str)               ?? 'string'
          !! nqp::istype(v, Int)               ?? 'integer'
          !! nqp::istype(v, Numeric)           ?? 'number'
          !! nqp::istype(v, Map)               ?? 'object'
          !! nqp::istype(v, Positional)        ?? 'array'
          !! v.^name
    }
    my %expected := { '@' => 'array', '%' => 'object', '~' => 'string', '#' => 'integer' };

    my \value = $format
      ?? Rakudo::Internals::RakFormat.decode($format, $text, $target)
      !! $sigil eq '@' ?? $text.lines.Array
      !! $sigil eq '#' ?? ($text.trim.Int // $text.trim)
      !! $text;

    if %expected{$sigil} -> $expected {
        my $found := shape(value);
        X::Rak::Format::Shape.new(
          :$target, :format($format // Str), :$name, :$expected, :$found,
          :reason("expected $expected for $name, found $found")
        ).throw unless $found eq $expected;
    }
    $RAK-LOADED := value if $format;
    $sigil eq '@' || $sigil eq '%' ?? value<> !! value
}

# Commands (see rak-plans/features/commands.md). The value of a command run at
# statement level is its Proc, which is not an error when sunk.
my class Rakudo::Internals::RakProc is Proc {
    has $.emits is rw = 'lines';    # from the command catalog
    method sink(--> Nil) { }
}

# A folder of rak's per-user files, following XDG on every platform
# (docs/adr/0006): `config` is $XDG_CONFIG_HOME/rak, `state` is
# $XDG_STATE_HOME/rak. An unset, empty or relative variable gives the XDG
# default, ~/.config or ~/.local/state.
sub RAK-XDG-DIR(Str:D $kind --> IO::Path:D) is implementation-detail {
    my ($var, $default) = $kind eq 'state'
      ?? ('XDG_STATE_HOME', '.local/state')
      !! ('XDG_CONFIG_HOME', '.config');
    my $dir := %*ENV{$var};
    ($dir && $dir.IO.is-absolute
      ?? $dir.IO
      !! ($*HOME || $*TMPDIR).add($default)
    ).add('rak')
}

my $RAK-STATUS;                   # last exit status, process-global
my $RAK-STATUSES = ();            # every command of the last pipeline
my @RAK-PIPE-PROCS;               # the commands of the running pipeline
my %RAK-PIPE-READ;                # those whose output a rak stage reads
my class Rakudo::Internals::RakNoStdin is implementation-detail { }
my $RAK-OLDPWD;                   # for `cd -`
sub RAK-STATUS() is implementation-detail { $RAK-STATUS }
sub RAK-STATUSES() is implementation-detail { $RAK-STATUSES<> }

# A command that is neither a path to an executable nor found on $PATH. It
# is an error, not an exit status: spawning it would only give exit code -1.
my class X::Rak::Command::NotFound is Exception {
    has Str $.name;
    method message() { "$!name: command not found" }
}
sub RAK-COMMAND-EXISTS(Str:D $name --> Bool:D) {
    my &runnable = { .x && .f };
    return runnable($name.IO) if $name.contains('/');
    (%*ENV<PATH> // '').split(':').first({ runnable(($_ || '.').IO.add($name)) }).defined
}

# Runs an external command. The redirection targets come as named
# arguments. With $capture, standard output is captured and returned as a Str.
sub RAK-RUN-COMMAND(Str:D $name, $capture is copy, *@args,
  :$out is copy, :$append, :$in is copy, :$err is copy, :$merge,
  Mu :$stdin is raw = Rakudo::Internals::RakNoStdin, :$piped
) is implementation-detail {
    X::Rak::Command::NotFound.new(:$name).throw unless RAK-COMMAND-EXISTS($name);
    # In a pipeline (see rak-plans/features/pipelines.md), :stdin is the previous
    # stage's value, and a :piped command is not waited for: its Proc is the
    # value, and RAK-PIPE-END waits for it.
    my @open;
    my $feed := nqp::not_i(nqp::eqaddr($stdin, Rakudo::Internals::RakNoStdin));
    # A URL target: the output is captured, then POSTed as JSON.
    my $url;
    for ($append, $in, $err) -> $t {
        X::Rak::HTTP.new(:url(~$t),
          :reason("a command's output can only be sent to a URL with >url")
        ).throw if $t.defined && Rakudo::Internals::RakHTTP.is-url(~$t);
    }
    if $out.defined && Rakudo::Internals::RakHTTP.is-url(~$out) {
        $url = ~$out;
        $out = Nil;
        $capture = 1;
    }
    $out = $out.defined    ?? open(~$out, :w)    !! Nil;
    $out = open(~$append, :a) if $append.defined;
    $in  = $in.defined     ?? open(~$in, :r)
        !! $feed && nqp::istype($stdin, Rakudo::Internals::RakProc)
                           ?? $stdin.out
        !! $feed           ?? True
        !! '-';
    $err = $err.defined    ?? open(~$err, :w)    !! '-';
    @open.push($_) for ($out, $in, $err).grep({ nqp::istype($_, IO::Handle) && nqp::not_i(nqp::istype($_, IO::Pipe)) });
    $out = $capture || $piped ?? True !! '-' without $out;
    # irak holds what rak code prints: show it before the command writes.
    $*OUT.flush if nqp::istype($out, Str) && $out eq '-';
    # The command catalog: what the command reads and emits. A value fed to
    # it is encoded now, so that a value it cannot read is an error before
    # it runs.
    my %caps = Rakudo::Internals::RakCatalog.caps($name, @args);
    my $text := $feed && $in ~~ Bool
      ?? RAK-PIPE-TEXT($stdin, $name, %caps<reads>) !! Nil;
    my $proc := Rakudo::Internals::RakProc.new(:$in, :$out, :$err, :merge(?$merge));
    $proc.emits = %caps<emits>;
    $proc.spawn($name, |@args.map(*.Str), :cwd($*CWD));
    # Fed by a command: when this one exits, the writer gets the SIGPIPE a
    # kernel pipe would give it (rakudo keeps the pipe's read end open).
    nqp::getattr($proc, Proc, '$!finished').then({ RAK-SIGPIPE($stdin) })
      if $feed && nqp::istype($stdin, Rakudo::Internals::RakProc)
         && nqp::isconcrete(nqp::getattr($proc, Proc, '$!finished'));
    @RAK-PIPE-PROCS.push($proc) if $feed || $piped;
    if $feed && $in ~~ Bool {
        start {
            CATCH { default { } }      # the reader went away: stop writing
            $proc.in.print($_) for $text;
            $proc.in.close;
        }
    }
    return $proc if $piped;
    my $result := $capture && $out ~~ Bool ?? $proc.out.slurp(:close) !! $proc;
    $proc.exitcode;               # waits for the child
    .close for @open;
    $RAK-STATUS = $proc;
    $RAK-STATUSES = ($proc,);
    # A command that failed sends nothing.
    return $proc if $url.defined && $proc.exitcode;
    $result := Rakudo::Internals::RakHTTP.post: $url,
      Rakudo::Internals::RakFormat.encode('json',
        Rakudo::Internals::RakFormat.decode('json', $result, $url), $url)
      if $url.defined;
    $result
}

sub RAK-CD(*@args) is implementation-detail {
    my $old = $*CWD;
    my $dir = !@args          ?? $*HOME
           !! @args[0] eq '-' ?? ($RAK-OLDPWD // $*CWD)
           !! @args[0];
    &*chdir(~$dir);
    $RAK-OLDPWD = $old;
    $*CWD
}

# `type name`: every meaning of each name, rak first, in bash's wording.
sub RAK-TYPE(@names, @known, $capture, @aliases = ()) is implementation-detail {
    my @lines;
    for @names.kv -> $i, $name {
        my $before = +@lines;
        @lines.push: "$name is aliased to `@aliases[$i]'" if @aliases[$i];
        @lines.push: "$name is a rak routine" if @known[$i];
        @lines.push: "$name is a shell builtin" if $name eq 'cd' | 'type';
        for $*SPEC.path -> $dir {
            my $p = $dir.IO.add($name);
            @lines.push: "$name is $p" if $p.f && $p.x;
        }
        @lines.push: "type: $name: not found" if +@lines == $before;
    }
    unless $capture { .say for @lines }
    @lines
}

# Aliases (rak-plans/features/aliases.md). An alias is the lexical constant
# `RAK-ALIAS name`: its text, then its words, joined by NULs. Declaring one
# shows nothing.
sub RAK-ALIAS-DECLARED(Mu $) is implementation-detail { Empty }

# `alias` alone lists the aliases seen from the caller, `alias name …` some
# of them, in bash's wording.
sub RAK-ALIASES($capture, *@names) is implementation-detail {
    my %text;
    my $ctx := nqp::ctxcaller(nqp::ctx());
    until nqp::isnull($ctx) {
        my $pad  := nqp::ctxlexpad($ctx);
        my $iter := nqp::iterator($pad);
        while $iter {
            my str $key = nqp::iterkey_s(nqp::shift($iter));
            if nqp::eqat($key, 'RAK-ALIAS ', 0) {
                my str $name = nqp::substr($key, 10);
                %text{$name} //= nqp::atkey($pad, $key).split("\0").head;
            }
        }
        $ctx := nqp::ctxouter($ctx);
    }
    my @lines = @names
      ?? @names.map({ %text{$_}:exists ?? "alias $_='%text{$_}'" !! "alias: $_: not found" })
      !! %text.keys.sort.map({ "alias $_='%text{$_}'" });
    unless $capture { .say for @lines }
    @lines
}

# `cat` with one argument naming a file with a format (`cat f.yaml`): the
# format, else Nil. Its output is decoded as a load of that file would be,
# with a warning that the redirection is preferred (rak-plans/features/pipelines.md).
sub RAK-CAT-FORMAT(Mu \v) is implementation-detail {
    my @c = v.command;
    return Nil unless @c.elems == 2 && @c[0] eq 'cat';
    my $path := @c[1].Str;
    my $format := Rakudo::Internals::RakFormat.of($path);
    return Nil unless $format && $path.IO.f;
    note "cat $path: the redirection <$path is preferred";
    $format
}

# A rak stage's input: a piped command's output becomes its lines, unless it
# is `cat f.yaml` (or another format); `:raw` keeps the lines for a decode
# stage.
sub RAK-PIPE-VALUE(Mu \v, :$raw) is raw is implementation-detail {
    if nqp::istype(v, Rakudo::Internals::RakProc) {
        %RAK-PIPE-READ{v.WHICH} = True;
        return v.out.lines if $raw;
        my $cat := RAK-CAT-FORMAT(v);
        $cat
          ?? Rakudo::Internals::RakFormat.decode($cat,
               v.out.slurp(:close), v.command[1].Str)
          !! RAK-PIPE-DECODE(v)
    }
    else { v<> }
}

# A command's output as the catalog says it emits: lines, one string, or
# decoded. JSON may be several documents, as jq prints: one is itself,
# several a list.
sub RAK-PIPE-DECODE(Mu \v) is raw is implementation-detail {
    my $emits := v.emits;
    my $target := v.command[0].IO.basename;
    if $emits eq 'json' {
        my @docs = Rakudo::Internals::RakJSONDecoder.stream(
          v.out.slurp(:close), $target);
        @docs.elems == 1 ?? @docs[0] !! @docs.List
    }
    elsif $emits eq 'jsonl' || $emits eq 'yaml' {
        Rakudo::Internals::RakFormat.decode($emits, v.out.slurp(:close), $target)
    }
    elsif $emits eq 'text' {
        v.out.slurp(:close)
    }
    else {
        v.out.lines
    }
}

# The formatter, `.` (rak-plans/features/formatter.md): its input as JSON
# documents. A command's output and a Str are text: a stream of JSON values,
# else a rak data literal, else one string. A Seq gives one document per
# value; anything else is one document.
sub RAK-FORMAT(Mu \v) is implementation-detail {
    my sub text(Str:D $text) {
        my @docs = try Rakudo::Internals::RakJSONDecoder.stream($text, 'formatter', :ordered);
        return @docs unless $!;
        my \data = Rakudo::Internals::RakDataReader.read($text);
        nqp::eqaddr(data, Rakudo::Internals::RakDataReader)
          ?? ($text,)
          !! (data,)
    }
    my @docs;
    if nqp::istype(v, Rakudo::Internals::RakProc) {
        %RAK-PIPE-READ{v.WHICH} = True;
        my $format := RAK-CAT-FORMAT(v);
        $format
          ?? @docs.push(Rakudo::Internals::RakFormat.decode($format,
               v.out.slurp(:close), v.command[1].Str))
          !! v.emits eq 'yaml' || v.emits eq 'jsonl'
            ?? @docs.push(RAK-PIPE-DECODE(v))
            !! @docs.append(text(v.out.lines.join("\n")));
    }
    elsif nqp::istype(v, Seq) {
        for v<> -> \e {
            nqp::istype(e, Str) && nqp::isconcrete(e)
              ?? @docs.append(text(e))
              !! @docs.push(nqp::istype(e, Seq) ?? e.cache !! e);
        }
    }
    elsif nqp::istype(v, Str) && nqp::isconcrete(v) {
        @docs.append: text(v);
    }
    else {
        @docs.push: v<>;
    }
    Rakudo::Internals::RakFormatted.from-docs(@docs)
}

# Output redirection of the formatter's value: what it would print is the
# statement's output, and the value becomes a plain Str (so it is not shown
# again once the statement ends).
sub RAK-REDIRECT-FORMATTED(Mu \r) is raw is implementation-detail {
    if nqp::istype(r, Rakudo::Internals::RakFormatted) {
        $*OUT.print: r.plain ~ "\n" if r.chars;
        r.plain
    }
    else { r }
}

sub RAK-PIPE-CALL(&stage, Mu \v) is raw is implementation-detail { stage(v) }

# The text of a `to-yaml`, `to-json`, `to-jsonl` or `to-text` stage: a Str,
# which a command gets verbatim (rak-plans/features/pipelines.md).
my class Rakudo::Internals::RakEncoded is Str is implementation-detail { }

sub RAK-TO(Str:D $format, Mu \v) is implementation-detail {
    my str $text = $format eq 'text'
      ?? (nqp::istype(v, Iterable) ?? v.join("\n") !! v.Str)
      !! Rakudo::Internals::RakFormat.encode($format, v, 'to-' ~ $format);
    nqp::box_s($text, Rakudo::Internals::RakEncoded)
}

# A value written to a command, as text chunks (rak-plans/features/
# command-catalog.md#choosing-a-format), given the formats it reads. A
# `to-…` stage's text goes verbatim. A Str, a number or a flat list is lines:
# a filesize its bytes, a Duration its nanoseconds, a DateTime RFC 3339. A
# hash, or a list holding a hash or a list, is YAML, else JSON Lines, else
# JSON; a lazy Seq is written item by item, so its first item decides. A
# flat value to a command that does not read lines is encoded too.
sub RAK-PIPE-TEXT(Mu \v, Str:D $name = 'pipe', $reads = ('lines', 'yaml')) is implementation-detail {
    my sub structured(Mu \e) {
        nqp::isconcrete(e)
          && (nqp::istype(e, Associative) || nqp::istype(e, Positional))
    }
    my sub flat(Mu \e) {
        (nqp::isconcrete(e)
          ?? nqp::istype(e, Duration)
            ?? (e.Rat * 1_000_000_000).round.Str
            !! nqp::istype(e, Instant)
              ?? DateTime.new(e).Str
              !! e.Str
          !! '') ~ "\n"
    }
    my sub json(Mu \e) {
        Rakudo::Internals::RakFormat.encode('jsonl', (e,), $name)
    }
    my sub yaml(Mu \e) { Rakudo::Internals::RakYAML.encode((e,), $name) }
    if nqp::istype(v, Rakudo::Internals::RakEncoded) {
        my str $t = v;
        return ($t.ends-with("\n") || $t eq '' ?? $t !! $t ~ "\n",);
    }
    my @reads = $reads.list;
    my $list := nqp::isconcrete(v) && nqp::istype(v, Iterable)
      && nqp::not_i(nqp::istype(v, Str)) && nqp::not_i(nqp::istype(v, Associative));
    my $iter;
    my \first = $list ?? ($iter := v.iterator).pull-one !! v;
    return () if $list && nqp::eqaddr(first, IterationEnd);
    my $data := $list
      ?? (nqp::istype(v, List) && nqp::not_i(v.is-lazy)
           ?? v.first(&structured, :k).defined
           !! structured(first))
      !! structured(v);
    my $format := $data
      ?? @reads.first({ $_ eq 'yaml' || $_ eq 'jsonl' || $_ eq 'json' })
      !! @reads.first({ $_ eq 'lines' || $_ eq 'jsonl' || $_ eq 'json' || $_ eq 'yaml' });
    X::Rak::Pipe::Format.new(:$name, :@reads,
      :what($data ?? 'structured data' !! 'lines')).throw
      unless $format.defined;
    # One document: JSON, or a lone value.
    if $format eq 'json' {
        return (Rakudo::Internals::RakFormat.encode('json', v, $name),) unless $list;
        my @all = first;
        loop {
            my \e = $iter.pull-one;
            last if nqp::eqaddr(e, IterationEnd);
            @all[@all.elems] = e;
        }
        return (Rakudo::Internals::RakFormat.encode('json', @all, $name),);
    }
    return ($format eq 'yaml'
      ?? Rakudo::Internals::RakYAML.encode(v, $name)
      !! $format eq 'jsonl' ?? json(v) !! flat(v),) unless $list;
    my &chunk := $format eq 'yaml' ?? &yaml !! $format eq 'jsonl' ?? &json !! &flat;
    gather {
        take chunk(first);
        loop {
            my \e = $iter.pull-one;
            last if nqp::eqaddr(e, IterationEnd);
            take chunk(e);
        }
    }
}

sub RAK-FROM-JSON(Mu \v) is implementation-detail {
    my $text = nqp::istype(v, Iterable) ?? v.join("\n") !! v.Str;
    Rakudo::Internals::RakFormat.decode('json', $text, 'pipe')
}

sub RAK-FROM-JSONL(Mu \v) is implementation-detail {
    (nqp::istype(v, Iterable) ?? v !! v.Str.lines)
      .grep(*.trim)
      .map({ Rakudo::Internals::RakFormat.decode('json', $_, 'pipe') })
}

# Sends SIGPIPE to a pipeline command still running: its reader went away.
sub RAK-SIGPIPE(Mu \p --> Nil) is implementation-detail {
    my $finished := nqp::getattr(nqp::decont(p), Proc, '$!finished');
    try nqp::getattr(nqp::decont(p), Proc, '$!proc').kill(13)
      if nqp::isconcrete($finished) && $finished.status ~~ Planned;
}

# The end of a pipeline: its value is made whole, the commands are waited
# for, and $? is the first that failed, else the last. A command whose output
# a rak stage stopped reading gets SIGPIPE, which is not a failure.
sub RAK-PIPE-END(Mu \v) is raw is implementation-detail {
    my \value := nqp::istype(v, Seq) ?? v.cache.eager !! v<>;
    my @procs = @RAK-PIPE-PROCS;
    my %read  = %RAK-PIPE-READ;
    @RAK-PIPE-PROCS = ();
    %RAK-PIPE-READ  = ();
    # Proc drains stdout through a channel, so a writer never sees the
    # reader go away; it gets SIGPIPE instead.
    for @procs -> $p {
        next unless %read{$p.WHICH};
        RAK-SIGPIPE($p);
        $p.out.close;
    }
    my $status;
    for @procs.kv -> $i, $p {
        $p.exitcode;
        next if $p.signal == 13 && $i < @procs.end;
        $status //= $p if $p.exitcode || $p.signal;
    }
    if @procs {
        $RAK-STATUS = $status // @procs.tail;
        $RAK-STATUSES = @procs.List;
    }
    value
}

# vim: expandtab shiftwidth=4
