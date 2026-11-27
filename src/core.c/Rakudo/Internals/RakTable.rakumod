# Tables (rak-plans/features/tables.md): a list of hashes shown as a grid, as
# nushell does, the typed values its cells hold, and the builtins that make a
# nushell-like `ls`: `ls`, the topical commands `select`, `reject`, `drop`,
# `sort-by`, `get`, `table`, `into`. Settings come from `$*RAK-CONFIG`, which
# uses the names of nushell's `$env.config`.

my class Rakudo::Internals::RakTable { ... }

# A filesize: a number of bytes that shows in metric units (`1.2 MB`).
my class Rakudo::Internals::RakFilesize is Int is implementation-detail {
    method new(Int() $bytes) { nqp::fromI_I(nqp::decont($bytes), self) }
    method Int() { nqp::fromI_I(nqp::decont(self), Int) }
    multi method gist(Rakudo::Internals::RakFilesize:D:) {
        Rakudo::Internals::RakTable.filesize-text(self)
    }
}

# The `table` command's value: the grid as text, with no width limit and no
# colour. Sunk at statement level, or shown by irak, it renders again for the
# terminal it is printed to.
my class Rakudo::Internals::RakTableText is Str is implementation-detail {
    has $!rows;
    has $!width;

    method from-rows(\rows, $width) {
        my $text := Rakudo::Internals::RakTable.render(rows, :width($width // Inf));
        my $self := nqp::box_s(nqp::unbox_s($text), self);
        nqp::bindattr($self, Rakudo::Internals::RakTableText, '$!rows', rows);
        nqp::bindattr($self, Rakudo::Internals::RakTableText, '$!width', $width);
        $self
    }

    method show(:$width, :$color --> Nil) {
        Rakudo::Internals::RakTable.show($!rows, :width($!width // $width), :$color)
    }

    method sink(--> Nil) { self.show }

    method plain() { nqp::box_s(nqp::unbox_s(self), Str) }
}

my class X::Rak::Table is Exception {
    has Str $.command;
    has Str $.reason;
    method message() { "$!command: $!reason" }
}

my class Rakudo::Internals::RakTable is implementation-detail {

    # --- settings -----------------------------------------------------------

    # An ordered hash from pairs; a value that is a list of pairs nests.
    my sub ordered(@pairs) {
        my %h is Hash::Ordered;
        for @pairs -> $p {
            %h{$p.key} = nqp::istype($p.value, List) ?? ordered($p.value) !! $p.value;
        }
        %h
    }

    # The defaults of `$*RAK-CONFIG`, nushell's names and values.
    method default-config() {
        ordered((
          'table' => (mode => 'rounded', index_mode => 'always'),
          'color_config' => (header => 'green_bold', row_index => 'green_bold'),
          'filesize' => (unit => 'metric', precision => 1),
          'datetime_format' => (normal => Any, table => Any),
          'commands' => Rakudo::Internals::RakCatalog.load,
        ))
    }

    # A setting, by its path; the default when it is missing or unset.
    method setting(*@path) {
        my $c := (try $*RAK-CONFIG) // Nil;
        for @path -> $k {
            last unless nqp::isconcrete($c) && nqp::istype($c, Associative);
            $c := $c.AT-KEY($k);
        }
        nqp::isconcrete($c) ?? $c !! Nil
    }

    # --- cells --------------------------------------------------------------

    my constant METRIC = <B kB MB GB TB PB EB>;
    my constant BINARY = <B KiB MiB GiB TiB PiB EiB>;

    method filesize-text(Int:D $bytes --> Str:D) {
        my $unit      = self.setting('filesize', 'unit') // 'metric';
        my $precision = (self.setting('filesize', 'precision') // 1).Int max 0;
        my $n = $bytes.Int;
        my sub show($value, $name) {
            sprintf("%.{$precision}f %s", $value, $name)
        }
        if $unit ne 'metric' && $unit ne 'binary' {
            my $fixed = METRIC.first({ .lc eq $unit.lc })
              // BINARY.first({ .lc eq $unit.lc });
            if $fixed.defined {
                return "$n B" if $fixed eq 'B';
                my $i     = (METRIC.first($fixed, :k) // BINARY.first($fixed, :k));
                my $base  = METRIC.first($fixed, :k).defined ?? 1000 !! 1024;
                return show($n / $base ** $i, $fixed);
            }
            $unit = 'metric';
        }
        my $base  = $unit eq 'binary' ?? 1024 !! 1000;
        my @names = $unit eq 'binary' ?? BINARY !! METRIC;
        return "$n B" if $n.abs < $base;
        my $i = 0;
        my $v = $n;
        while $v.abs >= $base && $i < @names.end { $v /= $base; ++$i }
        show($v, @names[$i])
    }

    # `1day 3hr 46min 40sec`, as nushell shows a duration.
    my constant DURATION-UNITS = (
      wk => 604800_000_000_000, day => 86400_000_000_000, hr => 3600_000_000_000,
      min => 60_000_000_000, sec => 1_000_000_000, ms => 1_000_000, 'µs' => 1_000,
      ns => 1,
    );

    method duration-text(Real:D $seconds --> Str:D) {
        my $ns = ($seconds.Rat * 1_000_000_000).round;
        return '0sec' unless $ns;
        my $sign = $ns < 0 ?? '-' !! '';
        $ns = $ns.abs;
        my @parts;
        for DURATION-UNITS -> $u {
            if $ns >= $u.value {
                @parts.push: ($ns div $u.value) ~ $u.key;
                $ns = $ns % $u.value;
            }
        }
        $sign ~ @parts.join(' ')
    }

    # `10 months ago`, `in 2 hours`, `now`, as nushell's tables show a date.
    method humanize(Real:D $seconds-ago --> Str:D) {
        my $s = $seconds-ago.abs;
        my sub n($v, $one, $many) { $v.round == 1 ?? $one !! "{$v.round} $many" }
        my $text =
             $s < 10       ?? return 'now'
          !! $s < 45       ?? "{$s.round} seconds"
          !! $s < 90       ?? 'a minute'
          !! $s < 45 * 60  ?? n($s / 60, 'a minute', 'minutes')
          !! $s < 90 * 60  ?? 'an hour'
          !! $s < 22 * 3600 ?? n($s / 3600, 'an hour', 'hours')
          !! $s < 36 * 3600 ?? 'a day'
          !! $s < 7 * 86400 ?? n($s / 86400, 'a day', 'days')
          !! $s < 11 * 86400 ?? 'a week'
          !! $s < 26 * 86400 ?? n($s / 604800, 'a week', 'weeks')
          !! $s < 45 * 86400 ?? 'a month'
          !! $s < 320 * 86400 ?? n($s / (30 * 86400), 'a month', 'months')
          !! $s < 548 * 86400 ?? 'a year'
          !! n($s / (365 * 86400), 'a year', 'years');
        $seconds-ago < 0 ?? "in $text" !! "$text ago"
    }

    # A small strftime: the conversions nushell's datetime_format uses most.
    method strftime(DateTime:D $d, Str:D $format --> Str:D) {
        my @days   = <Monday Tuesday Wednesday Thursday Friday Saturday Sunday>;
        my @months = <January February March April May June July August
                      September October November December>;
        my sub z($n, $w = 2) { sprintf(q[%0] ~ $w ~ q[d], $n) }
        my sub offset($sep) {
            my $o = $d.offset;
            ($o < 0 ?? '-' !! '+') ~ z($o.abs div 3600) ~ $sep ~ z($o.abs % 3600 div 60)
        }
        $format.subst(/'%' (<[a..zA..Z%]>) | '%:z'/, -> $m {
            my $c = $m[0].defined ?? ~$m[0] !! ':z';
            given $c {
                when 'Y' { $d.year }
                when 'y' { z($d.year % 100) }
                when 'm' { z($d.month) }
                when 'd' { z($d.day) }
                when 'e' { sprintf('%2d', $d.day) }
                when 'H' { z($d.hour) }
                when 'I' { z(($d.hour + 11) % 12 + 1) }
                when 'p' { $d.hour < 12 ?? 'AM' !! 'PM' }
                when 'M' { z($d.minute) }
                when 'S' { z($d.whole-second) }
                when 'j' { z($d.day-of-year, 3) }
                when 'a' { @days[$d.day-of-week - 1].substr(0, 3) }
                when 'A' { @days[$d.day-of-week - 1] }
                when 'b' { @months[$d.month - 1].substr(0, 3) }
                when 'B' { @months[$d.month - 1] }
                when 'F' { "{$d.year}-{z $d.month}-{z $d.day}" }
                when 'T' { "{z $d.hour}:{z $d.minute}:{z $d.whole-second}" }
                when 's' { $d.posix }
                when 'z' { offset('') }
                when ':z' { offset(':') }
                when '%' { '%' }
                default  { ~$m }
            }
        }, :g)
    }

    method datetime-text(Mu \v, :$table --> Str:D) {
        my $d = nqp::istype(v, Instant) ?? DateTime.new(v).local !! v;
        my $format = self.setting('datetime_format', $table ?? 'table' !! 'normal');
        return self.strftime($d, ~$format) if $format.defined;
        $table
          ?? self.humanize(now - $d.Instant)
          !! self.strftime($d, '%a, %d %b %Y %H:%M:%S %z')
             ~ ' (' ~ self.humanize(now - $d.Instant) ~ ')'
    }

    # The type a cell's colour is chosen by, in nushell's names.
    method cell-type(Mu \v --> Str:D) {
        !nqp::isconcrete(v)                              ?? 'nothing'
          !! nqp::istype(v, Rakudo::Internals::RakFilesize) ?? 'filesize'
          !! nqp::istype(v, Duration)                    ?? 'duration'
          !! nqp::istype(v, DateTime) || nqp::istype(v, Instant) ?? 'datetime'
          !! nqp::istype(v, Bool)                        ?? 'bool'
          !! nqp::istype(v, Int)                         ?? 'int'
          !! nqp::istype(v, Real)                        ?? 'float'
          !! nqp::istype(v, Str)                         ?? 'string'
          !! nqp::istype(v, Map)                         ?? 'record'
          !! nqp::istype(v, Positional)                  ?? 'list'
          !! 'string'
    }

    # How a value shows inside a cell.
    method cell-text(Mu \v --> Str:D) {
        given self.cell-type(v) {
            when 'nothing'  { '' }
            when 'filesize' { self.filesize-text(v) }
            when 'duration' { self.duration-text(v) }
            when 'datetime' { self.datetime-text(v, :table) }
            when 'bool'     { v ?? 'true' !! 'false' }
            when 'record'   { my $n = v.elems; $n == 1 ?? '{1 key}' !! "\{$n keys\}" }
            when 'list'     { my $n = v.elems; $n == 1 ?? '[1 item]' !! "[$n items]" }
            default         { v.Str.subst(/\v+/, ' ', :g) }
        }
    }

    # How irak shows a value that is no table: nushell's forms for durations
    # and dates.
    method value-text(Mu \v) {
        nqp::istype(v, Duration) && nqp::isconcrete(v)
          ?? self.duration-text(v)
          !! (nqp::istype(v, DateTime) || nqp::istype(v, Instant)) && nqp::isconcrete(v)
            ?? self.datetime-text(v)
            !! Nil
    }

    # --- colours ------------------------------------------------------------

    my constant COLOURS = %(
      black => 30, red => 31, green => 32, yellow => 33, blue => 34,
      purple => 35, magenta => 35, cyan => 36, white => 37, default => 39,
      dark_gray => 90, light_gray => 37, light_red => 91, light_green => 92,
      light_yellow => 93, light_blue => 94, light_purple => 95,
      light_magenta => 95, light_cyan => 96,
    );
    my constant ATTRS = %(
      bold => 1, b => 1, dimmed => 2, d => 2, italic => 3, i => 3,
      underline => 4, u => 4, blink => 5, l => 5, reverse => 7, r => 7,
      hidden => 8, h => 8, strike => 9, s => 9,
    );

    my sub rgb(Str() $c, $layer) {
        if $c ~~ /^ '#' (<xdigit>**2) (<xdigit>**2) (<xdigit>**2) $/ {
            return "{$layer};2;{:16(~$0)};{:16(~$1)};{:16(~$2)}";
        }
        my $code = COLOURS{$c.lc} // return Nil;
        $layer == 48 ?? $code + 10 !! $code
    }

    # The SGR codes of a colour as nushell spells it: `green_bold`,
    # `light_cyan`, `{fg: '#ff0000', bg: 'blue', attr: 'bu'}`.
    method sgr(Mu \c --> Str) {
        return Nil unless nqp::isconcrete(c);
        my @codes;
        if nqp::istype(c, Associative) {
            @codes.push: $_ with c<fg> && rgb(c<fg>, 38);
            @codes.push: $_ with c<bg> && rgb(c<bg>, 48);
            @codes.push: ATTRS{$_} // next for (c<attr> // '').comb;
        }
        else {
            my $s = c.Str.lc;
            for ATTRS.keys.grep(*.chars > 1) -> $a {
                if $s.ends-with("_$a") {
                    @codes.push: ATTRS{$a};
                    $s = $s.substr(0, *- ($a.chars + 1));
                    last;
                }
            }
            @codes.unshift: $_ with rgb($s, 38);
        }
        @codes ?? "\e[{@codes.join(';')}m" !! Nil
    }

    # --- the grid -----------------------------------------------------------

    # A table: a non-empty list whose elements are all hashes.
    method is-table(Mu \v --> Bool:D) {
        so nqp::isconcrete(v) && nqp::istype(v, Positional) && !nqp::istype(v, Map)
          && nqp::isconcrete(my $n := (try v.elems)) && $n > 0
          && v.list.first({
                 nqp::not_i(nqp::isconcrete($_)) || nqp::not_i(nqp::istype($_, Map))
                   || nqp::istype($_, Pair)
             }) === Nil
    }

    # The columns: the union of the rows' keys, in first-seen order. A plain
    # Hash has no order: its keys come sorted.
    method columns(@rows) {
        my %seen;
        my @columns;
        for @rows -> $row {
            for (nqp::istype($row, Hash::Ordered) ?? $row.keys !! $row.keys.sort) -> $k {
                @columns.push($k) unless %seen{$k}++;
            }
        }
        @columns
    }

    my constant MODES = %(
      #          top           middle        bottom        vertical  outer
      rounded => [<╭ ─ ┬ ╮>, <├ ─ ┼ ┤>, <╰ ─ ┴ ╯>, '│', True],
      ascii   => [<+ - + +>, <+ - + +>, <+ - + +>, '|', True],
      compact => [Nil,       <├ ─ ┼ ┤>, Nil,       '│', False],
      light   => [Nil,       <─ ─ ─ ─>, Nil,       ' ', False],
      none    => [Nil,       Nil,       Nil,       ' ', False],
    );

    # The grid of @rows as text: at most $width columns wide, in colour with
    # :color.
    method render(\rows, :$width = Inf, :$color --> Str:D) {
        my @rows = rows.list;
        my @columns = self.columns(@rows);
        my $mode = MODES{self.setting('table', 'mode') // 'rounded'} // MODES<rounded>;
        my ($top, $mid, $bottom, $v, $outer) = @$mode;

        # The index column: `#`, or the rows' own `index` with index_mode auto.
        my $index-mode = self.setting('table', 'index_mode') // 'always';
        my @index;
        if $index-mode eq 'auto' && @columns.first('index').defined {
            @index = @rows.map({ self.cell-text(.<index>) });
            @columns = @columns.grep(* ne 'index');
        }
        elsif $index-mode ne 'never' {
            @index = @rows.keys.map(~*);
        }

        my @header = @columns;
        my @cells  = @rows.map(-> $row { @columns.map({ $row{$_} }).List });
        my @text   = @cells.map(*.map({ self.cell-text($_) }).List);
        my @right  = @cells.map(*.map({
            nqp::istype($_, Real) && nqp::not_i(nqp::istype($_, Duration))
              && nqp::not_i(nqp::istype($_, Instant))
        }).List);

        # Natural widths, then fit: shrink the widest column, then drop the
        # rightmost columns behind a `…` column.
        my @w = @columns.keys.map(-> $c {
            ([max] @header[$c].chars, |@text.map({ .[$c].chars })) max 1
        });
        my $iw = @index ?? ([max] '#'.chars, |@index.map(*.chars)) !! 0;
        my sub total(@widths, $more = 0) {
            my $n = @widths + (@index ?? 1 !! 0) + $more;
            return 0 unless $n;
            ([+] @widths) + ($iw if @index) + $more + 2 * $n + ($n - 1)
              + ($outer ?? 2 !! 0)
        }
        my @min = @columns.keys.map({ @w[$_] min (@header[$_].chars max 4) });
        while total(@w) > $width {
            my @wide = @w.keys.grep({ @w[$_] > @min[$_] });
            last unless @wide;
            --@w[@wide.max({ @w[$_] })];
        }
        my $cut = False;
        if total(@w) > $width {
            $cut = True;
            @w.pop while @w && total(@w, 1) > $width;
            @columns = @columns.head(+@w);
            @header  = @header.head(+@w);
        }

        my $hdr = $color ?? self.sgr(self.setting('color_config', 'header') // 'green_bold') !! Nil;
        my $idx = $color ?? self.sgr(self.setting('color_config', 'row_index') // 'green_bold') !! Nil;
        my sub paint($text, $sgr) { $sgr ?? "$sgr$text\e[0m" !! $text }
        my sub fit(Str $t, $w) { $t.chars > $w ?? $t.substr(0, $w - 1) ~ '…' !! $t }
        # Pads to $w, painting only the text.
        my sub pad(Str $t, $w, $align, $sgr = Nil) {
            my $gap = $w - $t.chars;
            my $p = paint($t, $sgr);
            $align eq 'right'  ?? ' ' x $gap ~ $p
              !! $align eq 'center' ?? ' ' x ($gap div 2) ~ $p ~ ' ' x ($gap - $gap div 2)
              !! $p ~ ' ' x $gap
        }

        my @widths = (($iw if @index), |@w, (1 if $cut));
        my sub rule(@c) {
            return Nil unless @c;
            my ($l, $h, $j, $r) = @c;
            ($outer ?? $l !! '') ~ @widths.map({ $h x ($_ + 2) }).join($j) ~ ($outer ?? $r !! '')
        }
        my sub line(@cells) {
            my $edge = $outer ?? $v !! '';
            $edge ~ @cells.map({ " $_ " }).join($v) ~ $edge
        }

        my @lines;
        @lines.push: $_ with rule($top);
        @lines.push: line((
          (pad('#', $iw, 'center', $hdr) if @index),
          |@columns.keys.map({ pad(fit(@header[$_], @w[$_]), @w[$_], 'center', $hdr) }),
          ('…' if $cut),
        ));
        @lines.push: $_ with rule($mid);
        for @rows.keys -> $r {
            @lines.push: line((
              (pad(@index[$r], $iw, 'right', $idx) if @index),
              |@columns.keys.map(-> $c {
                  pad(fit(@text[$r][$c], @w[$c]), @w[$c],
                    @right[$r][$c] ?? 'right' !! 'left',
                    $color ?? self.sgr(self.setting('color_config',
                      self.cell-type(@cells[$r][$c]))) !! Nil)
              }),
              ('…' if $cut),
            ));
        }
        @lines.push: $_ with rule($bottom);
        @lines.map(*.subst(/\h+ $/, '')).join("\n")
    }

    # The width of the terminal on /dev/tty, or Nil.
    method terminal-width() {
        with %*ENV<COLUMNS> { return .Int if .Int > 0 }
        my $tty = try '/dev/tty'.IO.open;
        return Nil unless $tty;
        my @n = (try run('stty', 'size', :in($tty), :out, :err).out.slurp(:close).words) // ();
        try $tty.close;
        @n == 2 && @n[1] > 0 ?? +@n[1] !! Nil
    }

    # Prints the grid to $*OUT: on a terminal fitted to it and in colour,
    # otherwise whole and plain.
    method show(\rows, :$width is copy, :$color is copy --> Nil) {
        my $tty = ?(try $*OUT.t);
        $color //= $tty;
        $width //= $tty ?? (self.terminal-width // 80) !! Inf;
        $*OUT.print: self.render(rows, :$width, :$color) ~ "\n";
    }

    # --- conversions --------------------------------------------------------

    my constant SIZE-UNITS = %(
      b => 1, kb => 1000, mb => 1000**2, gb => 1000**3, tb => 1000**4,
      pb => 1000**5, eb => 1000**6, kib => 1024, mib => 1024**2,
      gib => 1024**3, tib => 1024**4, pib => 1024**5, eib => 1024**6,
    );
    my constant TIME-UNITS = %(
      ns => 1, us => 1_000, 'µs' => 1_000, ms => 1_000_000,
      sec => 1_000_000_000, min => 60_000_000_000, hr => 3600_000_000_000,
      day => 86400_000_000_000, wk => 604800_000_000_000,
    );

    method to-filesize(Mu \v) {
        return v if nqp::istype(v, Rakudo::Internals::RakFilesize);
        return Rakudo::Internals::RakFilesize.new(v.Int) if nqp::istype(v, Real);
        my $s = v.Str.trim;
        return Rakudo::Internals::RakFilesize.new($s.Int) if $s ~~ /^ <[+-]>? \d+ $/;
        if $s ~~ /^ (<[+-]>? \d+ ['.' \d+]?) \h* (<[a..zA..Z]>+) $/
          and SIZE-UNITS{$1.lc} -> $mult {
            return Rakudo::Internals::RakFilesize.new(($0.Rat * $mult).round);
        }
        X::Rak::Table.new(:command('into filesize'), :reason("cannot read '$s' as a filesize")).throw
    }

    method to-duration(Mu \v) {
        return v if nqp::istype(v, Duration);
        return Duration.new(v.Int / 1_000_000_000) if nqp::istype(v, Real);
        my $s = v.Str.trim;
        return Duration.new($s.Int / 1_000_000_000) if $s ~~ /^ <[+-]>? \d+ $/;
        my $t = $s.subst(/\s+/, '', :g);
        my $neg = $t.starts-with('-');
        $t .= subst(/^ <[+-]>/, '');
        my @m = $t.match(/ (\d+ ['.' \d+]?) (<-[\d.]>+) /, :g);
        my $ok = @m && @m.map(*.chars).sum == $t.chars
          && @m.map({ TIME-UNITS{~.[1]}:exists }).all;
        my $ns = $ok ?? @m.map({ .[0].Rat * TIME-UNITS{~.[1]} }).sum !! 0;
        X::Rak::Table.new(:command('into duration'), :reason("cannot read '{v}' as a duration")).throw
          unless $ok;
        Duration.new(($neg ?? -$ns !! $ns).round / 1_000_000_000)
    }

    method to-datetime(Mu \v) {
        return v if nqp::istype(v, DateTime);
        return DateTime.new(v) if nqp::istype(v, Instant);
        return DateTime.new(v.Real) if nqp::istype(v, Real);
        my $s = v.Str.trim;
        return DateTime.new($s.Int) if $s ~~ /^ <[+-]>? \d+ $/;
        my $d = try DateTime.new($s.subst(/^ (\d**4 '-' \d\d '-' \d\d) ' '/, {"$0T"}).subst(/'z' $/, 'Z'));
        return $d if $d.defined;
        $d = try Date.new($s).DateTime;
        return $d if $d.defined;
        X::Rak::Table.new(:command('into datetime'), :reason("cannot read '$s' as a datetime")).throw
    }
}

# --- builtins -----------------------------------------------------------------

# The user and group names, from /etc/passwd and /etc/group.
my %RAK-ID-NAMES;
sub RAK-ID-NAME(Str:D $file, Int:D $id) is implementation-detail {
    %RAK-ID-NAMES{$file} //= %(
      (try $file.IO.lines.map({ my @f = .split(':'); @f[2] => @f[0] if @f > 2 })) // ()
    );
    %RAK-ID-NAMES{$file}{$id} // ~$id
}

my sub rak-mode-text(Int:D $mode) {
    my @c = <r w x>;
    (8, 7 ... 0).map({ $mode +& (1 +< $_) ?? @c[(8 - $_) % 3] !! '-' }).join
}

# `ls`: a table of the entries of each path, a glob in the last component
# matching names. `-a` keeps dot files, `-l` adds mode, user, group, target.
sub RAK-LS(*@args, *%) is implementation-detail {
    my $all  = False;
    my $long = False;
    my @paths;
    for @args.map(*.Str) -> $a {
        if $a.starts-with('--') && $a.chars > 2 {
            given $a {
                when '--all'  { $all  = True }
                when '--long' { $long = True }
                default { X::Rak::Table.new(:command<ls>, :reason("unknown option $a")).throw }
            }
        }
        elsif $a.starts-with('-') && $a.chars > 1 {
            for $a.substr(1).comb {
                when 'a' { $all  = True }
                when 'l' { $long = True }
                default { X::Rak::Table.new(:command<ls>, :reason("unknown option -$_")).throw }
            }
        }
        else { @paths.push: $a }
    }
    @paths ||= '.';

    my sub join-path(Str $dir, Str $name) {
        $dir eq '.' ?? $name !! $dir.ends-with('/') ?? "$dir$name" !! "$dir/$name"
    }
    my sub glob-match(Str $glob, Str $name) {
        my @g = $glob.comb;
        my @s = $name.comb;
        my int $gi = 0; my int $si = 0; my int $star = -1; my int $mark = 0;
        while $si < @s {
            if $gi < @g && (@g[$gi] eq '?' || @g[$gi] eq @s[$si]) { ++$gi; ++$si }
            elsif $gi < @g && @g[$gi] eq '*' { $star = $gi; ++$gi; $mark = $si }
            elsif $star >= 0 { $gi = $star + 1; ++$mark; $si = $mark }
            else { return False }
        }
        ++$gi while $gi < @g && @g[$gi] eq '*';
        $gi == @g
    }
    my sub entries(Str $dir) {
        my $listing := try dir($dir);
        X::Rak::Table.new(:command<ls>, :reason("$dir: cannot read the directory")).throw
          without $listing;
        $listing.map(*.basename)
    }

    my @names;
    for @paths -> $p {
        if $p.contains(/<[*?]>/) {
            my $dir  = $p.contains('/') ?? $p.substr(0, $p.rindex('/') + 1) !! '.';
            my $base = $p.contains('/') ?? $p.substr($p.rindex('/') + 1) !! $p;
            my $dot  = $all || $base.starts-with('.');
            @names.append: entries($dir eq '' ?? '/' !! $dir)
              .grep({ $dot || !.starts-with('.') })
              .grep({ glob-match($base, $_) })
              .map({ $dir eq '.' && !$p.starts-with('./') ?? $_ !! "$dir$_" });
        }
        elsif nqp::lstat(nqp::unbox_s($p), nqp::const::STAT_ISDIR) == 1
          && nqp::lstat(nqp::unbox_s($p), nqp::const::STAT_ISLNK) == 0 {
            @names.append: entries($p).grep({ $all || !.starts-with('.') })
              .map({ join-path($p, $_) });
        }
        elsif nqp::lstat(nqp::unbox_s($p), nqp::const::STAT_EXISTS)
          || nqp::lstat(nqp::unbox_s($p), nqp::const::STAT_ISLNK) {
            @names.push: $p;
        }
        else {
            X::Rak::Table.new(:command<ls>, :reason("$p: no such file or directory")).throw;
        }
    }

    @names.sort.map(-> $name {
        my str $n = $name;
        my $link  = nqp::lstat($n, nqp::const::STAT_ISLNK) == 1;
        my %row is Hash::Ordered;
        %row<name> = $name;
        %row<type> = $link ?? 'symlink'
          !! nqp::lstat($n, nqp::const::STAT_ISDIR) == 1 ?? 'dir' !! 'file';
        %row<size> = Rakudo::Internals::RakFilesize.new(nqp::lstat($n, nqp::const::STAT_FILESIZE));
        %row<modified> = DateTime.new(
          Instant.from-posix(nqp::lstat_time($n, nqp::const::STAT_MODIFYTIME))).local;
        if $long {
            %row<mode>  = rak-mode-text(nqp::lstat($n, nqp::const::STAT_PLATFORM_MODE));
            %row<user>  = RAK-ID-NAME('/etc/passwd', nqp::lstat($n, nqp::const::STAT_UID));
            %row<group> = RAK-ID-NAME('/etc/group', nqp::lstat($n, nqp::const::STAT_GID));
            %row<target> = $link ?? nqp::readlink($n) !! Nil;
        }
        %row
    }).Array
}

# A redirected `ls`: a target with a format (`ls >files.yaml`) gets the
# table, encoded; any other redirection runs GNU ls.
sub RAK-LS-REDIRECTED($capture, *@args, *%redirs) is implementation-detail {
    my $target := %redirs<out> // %redirs<append>;
    if %redirs.elems == 1 && $target.defined
      && Rakudo::Internals::RakFormat.of(~$target) {
        RAK-REDIRECT-OUT(~$target, %redirs<append>:exists ?? 'a' !! 'w',
          { RAK-LS(|@args) })
    }
    else {
        RAK-RUN-COMMAND('ls', $capture, |@args, |%redirs)
    }
}

# The input of a topical command: what is piped into it, else the topic.
sub RAK-TOPICAL-INPUT(Mu \stdin, Mu \topic) is raw is implementation-detail {
    my \v = nqp::eqaddr(stdin, Rakudo::Internals::RakNoStdin)
      ?? topic
      !! RAK-PIPE-VALUE(stdin);
    nqp::istype(v, Seq) ?? v.cache !! v<>
}

# A table's rows, or a lone hash as one row.
my sub rak-rows(Str:D $command, Mu \v) {
    nqp::istype(v, Map) && nqp::isconcrete(v)
      ?? (v,)
      !! nqp::istype(v, Positional) || nqp::istype(v, Iterable)
        ?? v.list
        !! X::Rak::Table.new(:$command, :reason("needs a table, got {v.^name}")).throw
}

my sub rak-copy(Map:D $row, @keys) {
    my %h is Hash::Ordered;
    %h{$_} = $row{$_} for @keys;
    %h
}

my sub rak-keys(Map:D $row) {
    nqp::istype($row, Hash::Ordered) ?? $row.keys !! $row.keys.sort
}

# The topical commands (rak-plans/features/tables.md#topical-commands).
sub RAK-TOPICAL(Str:D $name, *@args,
  Mu :$stdin is raw = Rakudo::Internals::RakNoStdin, Mu :$topic is raw, :$piped
) is implementation-detail {
    my \input = RAK-TOPICAL-INPUT($stdin, $topic);
    my @a = @args.map(*.Str);
    my $lone = nqp::istype(input, Map) && nqp::isconcrete(input);
    given $name {
        when 'select' | 'reject' {
            my @rows = rak-rows($name, input).map(-> $row {
                rak-copy($row, $name eq 'select'
                  ?? @a
                  !! rak-keys($row).grep(* ∉ @a))
            });
            $lone ?? @rows[0] !! @rows
        }
        when 'drop' {
            my @rows = rak-rows($name, input);
            if @a && @a[0] eq 'column' {
                my $n = (@a[1] // 1).Int;
                my @columns = Rakudo::Internals::RakTable.columns(@rows);
                my @keep = @columns.head(max 0, @columns - $n);
                my @out = @rows.map({ rak-copy($_, @keep.grep(-> $k { .{$k}:exists })) });
                $lone ?? @out[0] !! @out
            }
            else {
                my $n = (@a[0] // 1).Int;
                @rows.head(max 0, @rows - $n).Array
            }
        }
        when 'sort-by' {
            my $reverse = so @a.grep('-r' | '--reverse');
            my @columns = @a.grep({ !.starts-with('-') });
            X::Rak::Table.new(:command<sort-by>, :reason('needs a column')).throw unless @columns;
            my @rows = rak-rows($name, input).sort(-> $x, $y {
                [||] @columns.map(-> $c {
                    my \l = $x{$c};
                    my \r = $y{$c};
                    !l.defined && !r.defined ?? Same
                      !! !l.defined ?? More
                      !! !r.defined ?? Less
                      !! l cmp r
                })
            });
            ($reverse ?? @rows.reverse !! @rows).Array
        }
        when 'get' {
            X::Rak::Table.new(:command<get>, :reason('needs a column')).throw unless @a;
            my $c = @a[0];
            $lone ?? input{$c} !! rak-rows($name, input).map({ .{$c} }).Array
        }
        when 'table' {
            my $width;
            for @a.kv -> $i, $w {
                $width = @a[$i + 1].Int if $w eq '-w' | '--width';
            }
            my @rows = $lone ?? (input,) !! rak-rows($name, input);
            Rakudo::Internals::RakTableText.from-rows(@rows, $width)
        }
        when 'into' {
            my $type = @a.shift
              // X::Rak::Table.new(:command<into>, :reason('needs filesize, duration or datetime')).throw;
            my &conv = do given $type {
                when 'filesize' { -> \v { Rakudo::Internals::RakTable.to-filesize(v) } }
                when 'duration' { -> \v { Rakudo::Internals::RakTable.to-duration(v) } }
                when 'datetime' { -> \v { Rakudo::Internals::RakTable.to-datetime(v) } }
                default {
                    X::Rak::Table.new(:command<into>, :reason("cannot convert into $type")).throw
                }
            };
            my &opt = -> \v { nqp::isconcrete(v) ?? conv(v) !! v };
            if @a {
                my @rows = rak-rows("into $type", input).map(-> $row {
                    my %h is Hash::Ordered;
                    for rak-keys($row) -> $k {
                        %h{$k} = $k ∈ @a ?? opt($row{$k}) !! $row{$k};
                    }
                    %h
                });
                $lone ?? @rows[0] !! @rows
            }
            elsif nqp::istype(input, Positional) || nqp::istype(input, Iterable) && !nqp::istype(input, Str) {
                input.list.map({ opt($_) }).Array
            }
            else {
                conv(input)
            }
        }
    }
}
