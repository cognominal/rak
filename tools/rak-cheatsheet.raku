# Render PLANS/docs/CHEATSHEET.md for the terminal, with its rak code
# highlighted as irak highlights it (PLANS/highlight.md).
#
#   ./rak tools/rak-cheatsheet.raku PLANS/docs/CHEATSHEET.md > PLANS/docs/CHEATSHEET.ans
#   less -R PLANS/docs/CHEATSHEET.ans
#
# It must run through the ./rak wrapper: the analysis uses the compiler that
# nqp::getcomp('Raku') returns, which is rak's only under the wrapper.

use nqp;

%*ENV<RAKUDO_LINE_EDITOR> = 'none';   # keep the irak history alone
my $repl  = REPL.new(nqp::getcomp('Raku'), {}, True);
my %sgr   = $repl.irak-sgr;
my $reset = "\e[0m";
my $bold  = "\e[1m";
my $dim   = "\e[2m";

# The examples leave out `my`, so an undeclared variable is shown as a
# variable, not flagged.
sub class-of(Str:D $class --> Str:D) { $class eq 'undeclared' ?? 'variable' !! $class }

# Where a comment starts on a line: a `#` that is not a rak `#` sigil (one
# followed by a letter), outside a quoted string.
sub comment-start(Str:D $line --> Int) {
    my $quote = '';
    for $line.comb.kv -> $i, $c {
        if $quote { $quote = '' if $c eq $quote; next }
        if $c eq '"' | "'" { $quote = $c; next }
        next unless $c eq '#';
        next if $i && $line.substr($i - 1, 1) ~~ /\S/;
        next if $line.substr($i + 1, 1) ~~ /<.alpha>/;
        return $i;
    }
    Int
}

# The analysis of $code, which follows $context (lines already analyzed,
# for their declarations): its spans, offsets in $code, or Nil when it does
# not parse.
sub analyze(Str:D $code, Str:D $context = '') {
    my $joint = $context ?? "\n" !! '';
    my %fb = $repl.irak-feedback($context ~ $joint ~ $code, :!declare);
    return Nil unless %fb<parsed>;
    my $skip = $context.chars + $joint.chars;
    %fb<spans>.grep({ .<from> >= $skip })
      .map({ %( from => .<from> - $skip, to => .<to> - $skip, class => class-of(.<class>) ) }).List
}

# A line with a `;` after its code, unless it ends with a comma.
sub terminated(Str:D $line --> Str:D) {
    my $end  = comment-start($line) // $line.chars;
    my $code = $line.substr(0, $end);
    $code ~~ / [ ',' | ';' ] \s* $ / || $code !~~ /\S/
      ?? $line
      !! $code ~ ';' ~ $line.substr($end)
}

# The spans of a block. A block often gathers one-line examples with no `;`
# between them, so it is analyzed as written, then with a `;` after each
# line, then line by line, each line after the lines before it that parsed.
sub spans-of(Str:D $text) {
    with analyze($text) { return $_ }
    my @lines = $text.split("\n");
    my @shift;            # where each line starts, in $text and with `;`
    my ($at, $at-t) = 0, 0;
    for @lines -> $line {
        @shift.push: (+$at, +$at-t);
        $at   += $line.chars + 1;
        $at-t += terminated($line).chars + 1;
    }
    with analyze(@lines.map(&terminated).join("\n")) -> @spans {
        # A span keeps its offset within its line: the `;` comes after it.
        return @spans.map(-> %s {
            my $i = @shift.first({ .[1] <= %s<from> }, :end, :k);
            my $d = @shift[$i][1] - @shift[$i][0];
            %( from => %s<from> - $d, to => %s<to> - $d, class => %s<class> )
        }).List;
    }
    my @spans;
    my $context = '';
    for @lines.kv -> $i, $line {
        # A line that clashes with the ones before it (a `sub` declared
        # again) is analyzed alone.
        with analyze($line, $context) // analyze($line) {
            @spans.append: .map({ %( from => .<from> + @shift[$i][0],
                                     to   => .<to>   + @shift[$i][0],
                                     class => .<class> ) });
            $context ~= ($context ?? "\n" !! '') ~ terminated($line);
        }
    }
    @spans
}

# A text with its spans, a line at a time, comments dimmed.
sub paint(Str:D $text, @spans --> Seq) {
    my $offset = 0;
    gather for $text.split("\n") -> $line {
        my $end     = $offset + $line.chars;
        my $comment = comment-start($line);
        my $code-end = $comment.defined ?? $offset + $comment !! $end;
        my $out = '';
        my $pos = $offset;
        for @spans.grep({ .<from> >= $offset && .<to> <= $code-end }).sort(*.<from>) {
            next if .<from> < $pos;
            $out ~= $text.substr($pos, .<from> - $pos)
                  ~ %sgr{.<class>} ~ $text.substr(.<from>, .<to> - .<from>) ~ $reset;
            $pos = .<to>;
        }
        $out ~= $text.substr($pos, $code-end - $pos);
        $out ~= $dim ~ $line.substr($comment) ~ $reset if $comment.defined;
        take $out;
        $offset = $end + 1;
    }
}

# Inline code: a phrase (code with a space, such as `ls -l`) is highlighted
# when it parses and reads as more than naked strings; anything else is
# bold. Out of context, a lone word would mislead (`NO_COLOR` would be a
# naked string), and so would a placeholder (`name args`, `{ block }`).
# An all-caps word (`STMT`, `LVALUE`) is a placeholder, not a naked string.
sub inline-code(Str:D $code --> Str:D) {
    if $code ~~ /\s/ {
        with analyze($code) -> @all {
            my @spans = @all.grep({
                .<class> ne 'naked-string' || $code.substr(.<from>, .<to> - .<from>) !~~ /^ <:Lu>+ $/
            });
            return paint($code, @spans).join ~ $*BOLD-ON
              if @spans.first(*.<class> ne 'naked-string');
        }
    }
    # A lone word that can only be a variable, or only a path.
    return %sgr<variable> ~ $code ~ $reset ~ $*BOLD-ON
      if $code ~~ /^ <[$@%&]> <[*?!.^]>? [ <.alpha> <[\w-]>* | <[_/!]> ] $/;
    return %sgr<path> ~ $code ~ $reset ~ $*BOLD-ON
      if $code ~~ /^ [ '/' | './' | '../' | '~/' ] <[\w.\-]> \S* $/;
    $bold ~ $code ~ $reset ~ $*BOLD-ON
}

# The width of a string on screen, without its SGR codes.
sub visible(Str:D $s --> Int:D) { $s.subst(/ \e '[' <[0..9;]>* 'm' /, '', :g).chars }

# Inline Markdown: code is highlighted or bold, bold stays bold, links
# become their text.
sub inline(Str:D $line --> Str) {
    $line.subst(:g, /
        | '`' $<code>=[ <-[`]>+ ] '`'
        | '**'
        | '[' $<link>=[ <-[\]]>+ ] '](' <-[)]>* ')'
    /, {
        $<code> ?? inline-code(~$<code>)
     !! $<link> ?? inline(~$<link>)
     !! bold-toggle()
    })
}

# `**` switches bold on and off, also across lines (a bold phrase may be
# wrapped). After a code span, which ends with a reset, bold is restored.
my $*BOLD-ON = '';
sub bold-toggle(--> Str:D) {
    $*BOLD-ON = $*BOLD-ON ?? '' !! $bold;
    $*BOLD-ON || $reset
}

# A table row: in an aligned table (:pad), each cell keeps the width of its
# source, padded at its end, so the columns stay aligned. A `|` in inline
# code does not end a cell.
sub table-row(Str:D $line, Bool :$pad --> Str) {
    my @cells = '';
    my $code = False;
    for $line.comb -> $c {
        $code = !$code if $c eq '`';
        if $c eq '|' && !$code { @cells.push: '' } else { @cells[*-1] ~= $c }
    }
    @cells.map({
        my $out = inline($_);
        $pad ?? $out ~ ' ' x (.chars - visible($out) max 0) !! $out
    }).join('|')
}

# A session block: what follows a prompt is code, the rest is irak's answer.
my token prompt { ^ [ '[' \d+ '] ' ]? '> ' }

sub MAIN(Str:D $file = 'PLANS/docs/CHEATSHEET.md') {
    my @block;
    my $fence;        # the language of the open fence, or Nil outside one
    my $aligned;      # whether the table being read is aligned
    for $file.IO.lines -> $line {
        if $line ~~ /^ '```' (\S*) / {
            if $fence.defined {
                my $text = @block.join("\n");
                if $fence eq 'rak' {
                    .say for paint($text, spans-of($text)).map('    ' ~ *);
                }
                else {
                    for @block -> $l {
                        if $l ~~ &prompt {
                            my $code = $l.substr($/.to);
                            say '    ', ~$/, paint($code, spans-of($code)).join;
                        }
                        else { say '    ', $l }
                    }
                }
                @block = ();
                $fence = Nil;
            }
            else { $fence = ~$0 }
        }
        elsif $fence.defined { @block.push: $line }
        elsif $line ~~ /^ ('#'+) \s+ (.*) / {
            say $0.chars <= 2 ?? "\e[1;4m" ~ $1 ~ $reset !! $bold ~ $1 ~ $reset;
        }
        elsif $line.starts-with('|') {
            $aligned = so $line ~~ / '----' / if $line ~~ /^ '|' [ <[\s:-]>+ '|' ]+ \s* $/;
            say table-row($line, :pad(?$aligned));
        }
        else {
            $aligned = False;
            $*BOLD-ON = '' unless $line ~~ /\S/;   # a paragraph ends
            say inline($line);
        }
    }
}

# vim: expandtab shiftwidth=4
