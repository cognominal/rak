# REPL-INSPECTOR.rakumod — Data structure inspector (YAML preview)
#
# Renders a value as a block-style YAML subset for irak's previews, such as
# the fzf preview pane of TAB completion (rak-plans/features/completion.md).
# Containers deeper than max-depth show as `{…}` / `[…]`; each level shows at
# most max-items entries. Lazy and one-shot iterables are never consumed.

class REPL::DataInspector {
    has Int $.max-depth = 3;
    has Int $.max-items = 50;

    method preview(Mu \subject, Int :$max-depth = $!max-depth,
                   Int :$max-items = $!max-items --> Str:D) {
        my @lines = self!block(subject<>, 0, $max-depth, $max-items);
        @lines.join("\n") ~ "\n"
    }

    method show(Mu \subject, |c) { print self.preview(subject, |c) }

    # The kind of a value: 'map', 'seq' or 'scalar'
    sub kind(Mu \v --> Str:D) {
        return 'scalar' unless v.DEFINITE;
        return 'scalar' if nqp::istype(v, Str) || nqp::istype(v, Numeric)
          || nqp::istype(v, Bool) || nqp::istype(v, Pair);
        return 'map'    if nqp::istype(v, Associative) || nqp::istype(v, Capture);
        return 'seq'    if nqp::istype(v, Positional);
        'scalar'
    }

    # A value that must not be iterated: lazy, or a Seq that would be used up
    sub unsafe(Mu \v --> Bool:D) {
        so nqp::istype(v, Seq) || (try v.is-lazy)
    }

    sub keys-of(Mu \v) {
        (nqp::istype(v, Capture) ?? v.hash.keys !! v.keys).map(*.Str).sort
    }

    # A container's lines at $depth; a scalar's single line
    method !block(Mu \v, Int $depth, Int $max-depth, Int $max-items) {
        given kind(v) {
            when 'scalar' { (self!scalar(v),) }
            when 'map'    { self!map(v, $depth, $max-depth, $max-items) }
            default       { self!seq(v, $depth, $max-depth, $max-items) }
        }
    }

    # `key: scalar`, or `key:` followed by the nested block indented
    method !entry(Str:D $head, Mu \v, Int $depth, Int $max-depth, Int $max-items) {
        my $k = kind(v);
        if $k eq 'scalar' {
            return ("$head " ~ self!scalar(v),);
        }
        if unsafe(v) {
            return ("$head <lazy>",);
        }
        my $n = $k eq 'map' ?? keys-of(v).elems !! v.elems;
        return ("$head " ~ ($k eq 'map' ?? '{}' !! '[]'),) unless $n;
        if $depth + 1 >= $max-depth {
            return ("$head " ~ ($k eq 'map' ?? "\{… $n key{'s' if $n != 1}\}"
                                            !! "[… $n item{'s' if $n != 1}]"),);
        }
        ($head, |self!block(v, $depth + 1, $max-depth, $max-items).map('  ' ~ *))
    }

    method !map(Mu \v, Int $depth, Int $max-depth, Int $max-items) {
        return ('<lazy>',) if unsafe(v);
        my @keys = keys-of(v);
        return ('{}',) unless @keys;
        my @lines;
        for @keys.head($max-items) -> $key {
            @lines.append: self!entry(self!key($key) ~ ':', v.AT-KEY($key),
              $depth, $max-depth, $max-items);
        }
        @lines.push: "# … {@keys - $max-items} more" if @keys > $max-items;
        @lines
    }

    method !seq(Mu \v, Int $depth, Int $max-depth, Int $max-items) {
        return ('<lazy>',) if unsafe(v);
        my $total = v.elems;
        return ('[]',) unless $total;
        my @lines;
        for ^min($total, $max-items) -> $i {
            @lines.append: self!entry('-', v.AT-POS($i), $depth, $max-depth, $max-items);
        }
        @lines.push: "# … {$total - $max-items} more" if $total > $max-items;
        @lines
    }

    method !key(Str:D $key --> Str:D) {
        plain($key) ?? $key !! quoted($key)
    }

    method !scalar(Mu \v --> Str:D) {
        return 'null' unless v.DEFINITE;
        return v ?? 'true' !! 'false' if nqp::istype(v, Bool);
        return ~v if nqp::istype(v, Int) || nqp::istype(v, Num);
        return v.Str if nqp::istype(v, Rational);
        if nqp::istype(v, Str) {
            my $s = v.chars > 200 ?? v.substr(0, 200) ~ '…' !! v;
            return plain($s) ?? $s !! quoted($s);
        }
        quoted(v.gist)
    }

    # Can $s be written unquoted?
    sub plain(Str:D $s --> Bool:D) {
        so $s ~~ /^ <[\w./]> <[\w\h./()+-]>* $/
          && $s !~~ /\h $/
          && $s !~~ /^ [ true | false | null | '~' | yes | no ] $/
          && $s !~~ /^ <[+-]>? [\d | '.' \d]/
    }

    sub quoted(Str:D $s --> Str:D) {
        '"' ~ $s.trans(['\\', '"', "\n", "\t", "\r"]
                    => ['\\\\', '\\"', '\\n', '\\t', '\\r']) ~ '"'
    }
}

sub inspect(Mu $value, |c) {
    REPL::DataInspector.new.show($value, |c);
}
