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
          !! Nil
    }

    method encode(Str:D $format, \value, Str:D $target --> Str:D) {
        self!json(value, $target, 0) ~ "\n"
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

    method !json(\v, Str:D $target, int $level --> Str:D) {
        my str $in  = nqp::x('  ', $level + 1);
        my str $out = nqp::x('  ', $level);
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
              ?? "\{\n" ~ @keys.map({
                     $in ~ Rakudo::Internals::JSON.to-json(.Str) ~ ': '
                       ~ self!json(v.AT-KEY($_), $target, $level + 1)
                 }).join(",\n") ~ "\n$out}"
              !! '{}'
        }
        elsif nqp::istype(v, List) || nqp::istype(v, Seq) || nqp::istype(v, Range) {
            my @items = v.list;
            @items
              ?? "[\n" ~ @items.map({
                     $in ~ self!json($_, $target, $level + 1)
                 }).join(",\n") ~ "\n$out]"
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
        ).throw if $mode eq 'a';

        my $capture := Rakudo::Internals::RakCapture.new;
        my \result = do {
            my $*OUT := $capture;
            my \r = code();
            nqp::istype(r, Seq) ?? r.eager !! r
        };
        Rakudo::Internals::RakFormat.write: $target, $capture.printed
          ?? $capture.text
          !! Rakudo::Internals::RakFormat.encode($format, result, $target);
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

# vim: expandtab shiftwidth=4
