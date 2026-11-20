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

    submethod BUILD(Str:D :$text, Str:D :$target) {
        $!text   = $text;
        $!end    = nqp::chars($text);
        $!target = $target;
    }

    method decode(Str:D $text, Str:D $target) {
        my $self := self.new(:$text, :$target);
        $self.document
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
        self!ws;
        until $!pos < $!end && self!char eq '}' {
            my str $key = self!key;
            self!ws;
            self!fail("expected ':' after a key")
              unless $!pos < $!end && self!char eq ':';
            ++$!pos;
            self!ws;
            %h{$key} = self!value;
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
        %h
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

my class Rakudo::Internals::RakFormat is implementation-detail {

    # The format a target's extension selects, ignoring case, or Nil.
    method of(Str:D $target) {
        my str $lc = nqp::lc($target);
        nqp::eqat($lc, '.json', nqp::chars($lc) - 5) && nqp::chars($lc) > 5
          ?? 'json'
          !! nqp::eqat($lc, '.jsonl', nqp::chars($lc) - 6) && nqp::chars($lc) > 6
            ?? 'jsonl'
            !! Nil
    }

    # JSON is written pretty. JSON Lines is one compact record per line: an
    # array (or other list) is one record per element, anything else is one
    # record.
    method encode(Str:D $format, \value, Str:D $target --> Str:D) {
        if $format eq 'jsonl' {
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
        if $format eq 'jsonl' {
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

    method !json(\v, Str:D $target, int $level, Bool :$compact --> Str:D) {
        my str $in  = $compact ?? '' !! nqp::x('  ', $level + 1);
        my str $out = $compact ?? '' !! nqp::x('  ', $level);
        my str $nl  = $compact ?? '' !! "\n";
        my str $sep = $compact ?? ',' !! ",\n";
        my str $col = $compact ?? ':' !! ': ';
        if nqp::istype(v, Failure) {
            v.throw
        }
        elsif nqp::not_i(nqp::isconcrete(v)) {
            'null'
        }
        elsif nqp::istype(v, Bool) {
            v ?? 'true' !! 'false'
        }
        elsif nqp::istype(v, Str) {
            Rakudo::Internals::JSON.to-json(v)
        }
        elsif nqp::istype(v, Int) {
            v.Str
        }
        elsif nqp::istype(v, Rational) {
            self!rational(v, $target)
        }
        elsif nqp::istype(v, Num) {
            self!num(v, $target)
        }
        elsif nqp::istype(v, Map) {
            my @keys = v.keys.sort;
            @keys
              ?? "\{$nl" ~ @keys.map({
                     $in ~ Rakudo::Internals::JSON.to-json(.Str) ~ $col
                       ~ self!json(v.AT-KEY($_), $target, $level + 1, :$compact)
                 }).join($sep) ~ "$nl$out}"
              !! '{}'
        }
        elsif nqp::istype(v, List) || nqp::istype(v, Seq) || nqp::istype(v, Range) {
            my @items = v.list;
            @items
              ?? "[$nl" ~ @items.map({
                     $in ~ self!json($_, $target, $level + 1, :$compact)
                 }).join($sep) ~ "$nl$out]"
              !! '[]'
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

# Output redirection, `STMT >target` / `STMT >>target`: run the thunked
# statement with $*OUT bound to the target for that statement alone. A target
# with a format is written whole, from the printed text or, if nothing was
# printed, from the encoded value.
sub RAK-REDIRECT-OUT(Str() $target, Str:D $mode, &code) is implementation-detail {
    my $format := Rakudo::Internals::RakFormat.of($target);
    if $format {
        X::Rak::Format.new(:$target, :$format,
          :reason("cannot append to a .json target, use .jsonl for one record per line")
        ).throw if $mode eq 'a' && $format eq 'json';

        my $capture := Rakudo::Internals::RakCapture.new;
        my \result = do {
            my $*OUT := $capture;
            my \r = code();
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
            # written, so a failure leaves the file as it was.
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
        my \result = code();
        nqp::istype(result, Seq) ?? result.eager !! result
    }
}

# Load, `LVALUE <target`: the target's content, for assignment to LVALUE. A
# target with a format is decoded and must have the shape the sigil asks for
# (@ an array, % an object, ~ a string, # an integer, $ anything). A target
# without one loads as lines for @, as the whole text otherwise.
sub RAK-LOAD(Str() $target, Str:D $sigil, Str:D $name) is raw is implementation-detail {
    my $format := Rakudo::Internals::RakFormat.of($target);
    my $text   := $target.IO.slurp;
    $text.throw if nqp::istype($text, Failure);

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
    $sigil eq '@' || $sigil eq '%' ?? value<> !! value
}

# Commands (see PLANS/features/commands.md). The value of a command run at
# statement level is its Proc, which is not an error when sunk.
my class Rakudo::Internals::RakProc is Proc {
    method sink(--> Nil) { }
}

my $RAK-STATUS;                   # last exit status, process-global
my $RAK-STATUSES = ();            # every command of the last pipeline
my @RAK-PIPE-PROCS;               # the commands of the running pipeline
my %RAK-PIPE-READ;                # those whose output a rak stage reads
my class Rakudo::Internals::RakNoStdin is implementation-detail { }
my $RAK-OLDPWD;                   # for `cd -`
sub RAK-STATUS() is implementation-detail { $RAK-STATUS }
sub RAK-STATUSES() is implementation-detail { $RAK-STATUSES<> }

# Runs an external command. The redirection targets come as named
# arguments. With $capture, standard output is captured and returned as a Str.
sub RAK-RUN-COMMAND(Str:D $name, $capture, *@args,
  :$out is copy, :$append, :$in is copy, :$err is copy, :$merge,
  Mu :$stdin is raw = Rakudo::Internals::RakNoStdin, :$piped
) is implementation-detail {
    # In a pipeline (see PLANS/features/pipelines.md), :stdin is the previous
    # stage's value, and a :piped command is not waited for: its Proc is the
    # value, and RAK-PIPE-END waits for it.
    my @open;
    my $feed := nqp::not_i(nqp::eqaddr($stdin, Rakudo::Internals::RakNoStdin));
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
    my $proc := Rakudo::Internals::RakProc.new(:$in, :$out, :$err, :merge(?$merge));
    $proc.spawn($name, |@args.map(*.Str), :cwd($*CWD));
    # Fed by a command: when this one exits, the writer gets the SIGPIPE a
    # kernel pipe would give it (rakudo keeps the pipe's read end open).
    nqp::getattr($proc, Proc, '$!finished').then({ RAK-SIGPIPE($stdin) })
      if $feed && nqp::istype($stdin, Rakudo::Internals::RakProc)
         && nqp::isconcrete(nqp::getattr($proc, Proc, '$!finished'));
    @RAK-PIPE-PROCS.push($proc) if $feed || $piped;
    if $feed && $in ~~ Bool {
        my \v := $stdin;
        start {
            CATCH { default { } }      # the reader went away: stop writing
            $proc.in.print($_) for RAK-PIPE-TEXT(v);
            $proc.in.close;
        }
    }
    return $proc if $piped;
    my $result := $capture && $out ~~ Bool ?? $proc.out.slurp(:close) !! $proc;
    $proc.exitcode;               # waits for the child
    .close for @open;
    $RAK-STATUS = $proc;
    $RAK-STATUSES = ($proc,);
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
sub RAK-TYPE(@names, @known, $capture) is implementation-detail {
    my @lines;
    for @names.kv -> $i, $name {
        my $before = +@lines;
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

# A rak stage's input: a piped command's output becomes its lines.
sub RAK-PIPE-VALUE(Mu \v) is raw is implementation-detail {
    if nqp::istype(v, Rakudo::Internals::RakProc) {
        %RAK-PIPE-READ{v.WHICH} = True;
        v.out.lines
    }
    else { v<> }
}

sub RAK-PIPE-CALL(&stage, Mu \v) is raw is implementation-detail { stage(v) }

# A value written to a command: a Str or a number is a line, a list one line
# per element, and a hash (or a list inside a list) a JSON Lines record.
sub RAK-PIPE-TEXT(Mu \v) is implementation-detail {
    my sub line(Mu \e) {
        nqp::istype(e, Associative) || nqp::istype(e, Positional)
          ?? Rakudo::Internals::RakFormat.encode('jsonl', (e,), 'pipe')
          !! e.Str ~ "\n"
    }
    nqp::istype(v, Associative) || nqp::not_i(nqp::isconcrete(v))
      ?? (line(v),)
      !! nqp::istype(v, Iterable)
        ?? v.map(&line)
        !! (line(v),)
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
