my class X::REPL::InvalidEnvironment is Exception {
    has $.reason is required;
    method message() { "Invalid REPL environment: $!reason" }
}

class REPL { ... }

do {
    my sub sorted-set-insert(@values, $value) {
        my $low        = 0;
        my $high       = @values.end;
        my $insert_pos = 0;

        while $low <= $high {
            my $middle = floor($low + ($high - $low) / 2);

            my $middle_elem = @values[$middle];

            if $middle == @values.end {
                if $value eq $middle_elem {
                    return;
                } elsif $value lt $middle_elem {
                    $high = $middle - 1;
                } else {
                    $insert_pos = +@values;
                    last;
                }
            } else {
                my $middle_plus_one_elem = @values[$middle + 1];

                if $value eq $middle_elem || $value eq $middle_plus_one_elem {
                    return;
                } elsif $value lt $middle_elem {
                    $high = $middle - 1;
                } elsif $value gt $middle_plus_one_elem {
                    $low = $middle + 1;
                } else {
                    $insert_pos = $middle + 1;
                    last;
                }
            }
        }

        splice(@values, $insert_pos, 0, $value);
    }

    # The terminal's rows and columns, 24×80 when unknown.
    my sub terminal-size() {
        my $tty = try '/dev/tty'.IO.open;
        my @n = (try run('stty', 'size', :in($tty), :out, :err).out.slurp(:close).words) // ();
        try $tty.close;
        @n == 2 && @n.all > 0 ?? (+@n[0], +@n[1]) !! (24, 80)
    }

    # irak: Terminal::LineEditor measures the terminal once per prompt. This
    # role, mixed into its CLIInput, turns SIGWINCH into a `Resize` key that
    # redraws the line at the new width, and keeps that width for the fields
    # the prompt builds afterwards (history up and down).
    my role IrakResize {
        has $!cols;                     # the width after the last resize
        has Str $!prompt = '';

        method special-actions() { set(|callsame.keys, 'resize') }

        method decoded() {
            Supply.merge: callsame, signal(SIGWINCH).map({ 'Resize' => $_ })
        }

        method prompt(Str:D $prompt = '', |c) {
            $!prompt = $prompt;
            $!cols   = Nil;
            callsame
        }

        method replace-input-field(:$display-width, :$field-start, |c) {
            nextwith
              :display-width($!cols.defined
                ?? max(1, $!cols - $field-start) !! $display-width),
              :$field-start, |c
        }

        method do-edit($action, $insert?) {
            $action eq 'resize' ?? self!resize !! nextsame
        }

        method !resize(--> Nil) {
            my $field = self.input-field or return;
            $!cols = terminal-size()[1];
            my $content = $field.buffer.contents;
            my $pos     = $field.insert-cursor.pos;
            # Redraw from the start of the line: the old field's own
            # clearing assumes the old width.
            self.clear-input-field;
            self.output.print("\r\e[J" ~ $!prompt);
            self.replace-input-field(:field-start($field.field-start), :$content,
              :display-width(0));
            # Show the line from its start when the cursor allows it.
            self.input-field.insert-cursor.move-to($pos);
            self.input-field.scroll-cursor.move-to(0);
            self.output.print(self.input-field.refresh-string(True));
            self.output.flush;
        }
    }

    my role ReadlineBehavior[$WHO] {
        my $Readline = try { require Readline }
        my $read = $Readline.new;
        if !Rakudo::Internals.IS-WIN {
            $read.read-init-file("/etc/inputrc");
            $read.read-init-file(%*ENV<INPUTRC> // "~/.inputrc");
        }
        method init-line-editor {
            $read.read-history($.history-file);
        }
        method repl-read(Mu \prompt) {
            my $line = $read.readline(prompt);

            if $line.defined && $line.match(/\S/) {
                $read.add-history($line);
                $read.append-history(1, $.history-file);
            }

            $line
        }
    }

    my role LinenoiseBehavior[$WHO] {
        my &linenoise                      = $WHO<&linenoise>;
        my &linenoiseHistoryAdd            = $WHO<&linenoiseHistoryAdd>;
        my &linenoiseSetCompletionCallback = $WHO<&linenoiseSetCompletionCallback>;
        my &linenoiseAddCompletion         = $WHO<&linenoiseAddCompletion>;
        my &linenoiseHistoryLoad           = $WHO<&linenoiseHistoryLoad>;
        my &linenoiseHistorySave           = $WHO<&linenoiseHistorySave>;

        method completions-for-line(Str $line, int $cursor-index) { ... }

        method history-file(--> Str:D) { ... }

        method init-line-editor {
            linenoiseSetCompletionCallback(sub ($line, $c) {
                eager self.completions-for-line($line, $line.chars).map(&linenoiseAddCompletion.assuming($c));
            });
            linenoiseHistoryLoad($.history-file);
        }

        method teardown-line-editor {
            my $err = linenoiseHistorySave($.history-file);
            return if !$err;
            note "Couldn't save your history to $.history-file";
        }

        method repl-read(Mu \prompt) {
            self.update-completions;
            my $line = linenoise(prompt);

            if $line.defined && $line.match(/\S/) {
                linenoiseHistoryAdd($line);
            }

            $line
        }
    }

    # irak: the one table of highlighting codes (rak-plans/highlight.md), used by
    # the input field and, through REPL.irak-sgr, by the cheat sheet.
    my %irak-sgr =
      keyword        => "\e[1;35m",
      routine        => "\e[36m",
      command        => "\e[1;32m",
      naked-string   => "\e[33m",
      undeclared     => "\e[4;31m",
      variable       => "\e[3m",
      path           => "\e[34m",
    ;

    my role TerminalLineEditorBehavior[$WHO] {
        my $cli-input = $WHO<CLIInput>;
        my $cli;

        method completions-for-line(Str $line, int $cursor-index) { ... }

        method history-file(--> Str:D) { ... }

        # irak: the input field colors each word of its buffer as the last
        # Enter read it (irak-colors), while the buffer holds that text.

        # A subclass of ScrollingSingleLineInput::ANSI whose
        # visible-input-field-string wraps each span in SGR codes. Widths and
        # cursor moves are computed from the plain buffer, so the zero-width
        # codes do not disturb them. The scroll logic is the parent's.
        my sub irak-input-class($repl) {
            my $parent := $WHO<ScrollingSingleLineInput>.WHO<ANSI>;
            my &plain  := $parent.^find_method('visible-input-field-string');
            my $class  := Metamodel::ClassHOW.new_type(:name<IrakInputField>);
            $class.^add_parent($parent);
            $class.^add_method('visible-input-field-string', my method () {
                my $contents := self.buffer.contents;
                my $colors   := $repl.irak-colors;
                return plain(self)
                  if %*ENV<NO_COLOR> || self.mask.defined
                  || !$colors || $colors<text> ne $contents;

                # The visible part of the buffer, from $scroll-pos to $last
                my $scroll-pos = self.scroll-cursor.pos;
                my $avail      = self.available-width;
                my $last       = self.insert-cursor.pos;
                my $end        = self.insert-cursor.end;
                ++$last while $last < $end
                  && self.substring-width($scroll-pos, $last) < $avail;
                --$last if self.substring-width($scroll-pos, $last) > $avail;

                my $string = $scroll-pos ?? self.left-scroll-mark
                                         !! self.left-no-scroll-mark;
                my $pos = $scroll-pos;
                for $colors<spans>.list {
                    my $from = max(.<from>, $pos);
                    my $to   = min(.<to>, $last);
                    next unless $from < $to && (%irak-sgr{.<class>}:exists);
                    $string ~= $contents.substr($pos, $from - $pos)
                      ~ %irak-sgr{.<class>} ~ $contents.substr($from, $to - $from)
                      ~ "\e[0m";
                    $pos = $to;
                }
                $string ~= $contents.substr($pos, $last - $pos);
                $string ~= ' ' x ($avail - self.substring-width($scroll-pos, $last));
                $string ~ ($last < $end ?? self.right-scroll-mark
                                        !! self.right-no-scroll-mark)
            });
            $class.^compose;
            $class
        }

        method init-line-editor {
            my sub get-completions($contents, $pos) {
                # irak: `!n` TAB puts submission n's source in the buffer.
                with self.irak-recall($contents) { return ($_,) }
                eager self.completions-for-line($contents, $pos)
            }
            # The role goes in before .new: the object starts its input
            # threads as it is built.
            my $irak  := so %*ENV<RAKUDO_RAK_FRONTEND> && %*ENV<RAKU_RAK_MODE>;
            my $class := $irak ?? $cli-input.^mixin(IrakResize) !! $cli-input;
            $cli = self.irak-on-finish
              ?? $class.new(:&get-completions, :input-class(irak-input-class(self)))
              !! $class.new(:&get-completions);
            $cli.bind-key('Resize', 'resize') if $irak;
            $cli.load-history($.history-file);
        }

        method teardown-line-editor {
            $cli.save-history($.history-file);
        }

        # irak OSC 133 marks may wrap the prompt: this editor prints the
        # prompt verbatim and takes the input field's start column from a
        # cursor-position query, so escapes in the prompt are not counted
        # as width, and edits redraw only the field, never the prompt.
        method osc133-capable(--> True) { }

        method repl-read(Mu \prompt) {
            self.update-completions;
            my $line = $cli.prompt(self.osc133-prompt(prompt.chop),
              :on-finish(self.irak-on-finish));

            if $line.defined && $line.match(/\S/) {
                $cli.add-history($line);
            }

            $line
        }
    }

    my role FallbackBehavior {
        method repl-read(Mu \prompt) {
            print prompt;
            $*IN.get
        }
    }

    my role Completions {
        has @!completions = CORE::.keys.flatmap({
                    /^ "&"? $<word>=[\w* <.lower> \w*] $/ ?? ~$<word> !! []
                }).sort;

        method update-completions(--> Nil) {
            my $context := self.compiler.context;

            return unless $context;

            my $pad := nqp::ctxlexpad($context);
            my $it := nqp::iterator($pad);

            while $it {
                my $k := nqp::iterkey_s(nqp::shift($it));
                my $m = $k ~~ /^ "&"? $<word>=[\w* <.lower> \w*] $/;
                next if !$m;
                my $word = ~$m<word>;
                sorted-set-insert(@!completions, $word);
            }

            my $PACKAGE = self.compiler.eval('$?PACKAGE', :outer_ctx($context));

            for $PACKAGE.WHO.keys -> $k {
                sorted-set-insert(@!completions, $k);
            }
        }

        method extract-last-word(Str $line) {
            my $m = $line ~~ /^ $<prefix>=[.*?] <|w>$<last_word>=[\w*]$/;

            return ( $line, '') unless $m;

            ( ~$m<prefix>, ~$m<last_word> )
        }

        method completions-for-line(Str $line, int $cursor-index) {
            return @!completions unless $line;

            # ignore $cursor-index until we have a backend that provides it
            my ( $prefix, $word-at-cursor ) = self.extract-last-word($line);

            # XXX this could be more efficient if we had a smarter starting index
            gather for @!completions -> $word {
                if $word ~~ /^ "$word-at-cursor" / {
                    take $prefix ~ $word;
                }
            }
        }
    }

    # irak paging (rak-plans/features/paging.md): $*OUT during a submission. It
    # holds what the submission prints, so irak can measure it and page it,
    # until 1 s after the first output or a flush; from then on it lets the
    # output through. A submission that prints nothing while it waits (a
    # load, a slow computation) is still paged when its output is long. It keeps a copy of everything for `!p`.
    my class IrakPage is IO::Handle {
        has $.out;                       # the terminal
        has $!lock;
        has $!held;                      # bytes not shown yet
        has $!all;                       # every byte written
        has Bool $.wrote    = False;
        has Bool $!released = False;
        has $!timer;
        my $paging = False;              # a pager is running

        my $esc = / \e [ '[' <[\x30..\x3F]>* <[\x20..\x2F]>* <[\x40..\x7E]>
                       | ']' .*? [ \x07 | \e '\\' ] ] /;

        submethod TWEAK() {
            self.encoding: 'utf8';
            $!lock := Lock.new;
            $!held := buf8.new;
            $!all  := buf8.new;
        }

        # A page for this submission, or Nil when irak does not page.
        method for(\out) {
            out.t && self.command ?? self.new(:out(out)) !! Nil
        }

        # The pager: RAK_PAGER, else PAGER, else less -R; '' when off.
        method command(--> Str:D) {
            %*ENV<RAK_PAGER>:exists
              ?? ~%*ENV<RAK_PAGER>
              !! (%*ENV<PAGER> || 'less -R')
        }

        method paging(--> Bool:D) { $paging }

        method WRITE(Blob:D $buf --> True) {
            $!lock.protect: {
                $!timer := $*SCHEDULER.cue({ self.release }, :in(1))
                  unless $!wrote;
                $!wrote = True;
                $!all.append: $buf;
                $!released ?? $!out.write($buf) !! $!held.append($buf);
            }
        }

        # Show what is held and let the rest through.
        method release(--> Nil) {
            $!lock.protect: {
                unless $!released {
                    $!released = True;
                    $!out.write($!held) if $!held.elems;
                    $!held := buf8.new;
                    $!out.flush;
                }
            }
        }

        method flush(--> True) { self.release }
        method t()      { $!out.t }
        method opened() { True }
        method close()  { True }
        method tell()   { $!lock.protect: { $!all.elems } }

        # Everything the submission printed.
        method text(--> Str:D) { $!lock.protect: { $!all.decode('utf8-c8') } }

        # The submission is over: page what is held if it is long, else
        # show it.
        method end(:$format --> Nil) {
            .cancel with $!timer;
            my $held;
            $!lock.protect: {
                unless $!released {
                    $!released = True;
                    $held := $!held.decode('utf8-c8');
                    $!held := buf8.new;
                }
            }
            return unless $held && $held.chars;
            self.long($held)
              ?? self.page($held, $format, $!out)
              !! $!out.print($held);
        }

        my sub plain(Str:D $text) { $text.subst($esc, '', :g) }

        # Longer than 5 lines or the terminal, wrapped lines counted.
        method long(Str:D $text --> Bool:D) {
            my @lines = plain($text).lines;
            return True  if @lines > 5;
            return False if @lines.map(*.chars).max <= 40;
            my ($rows, $cols) = terminal-size;
            ([+] @lines.map({ max 1, ceiling(.chars / $cols) })) > min(5, $rows)
        }

        # Show $text in the pager, then its summary.
        method page(Str:D $text, $format, \out --> Nil) {
            my $exit = 127;
            if self.command -> $command {
                $paging = True;
                LEAVE $paging = False;
                my $p = try shell $command, :in;
                if $p.defined {
                    try $p.in.print($text);
                    try $p.in.close;
                    $exit = try $p.exitcode;
                }
            }
            $exit == 127
              ?? out.print($text)        # no pager: show it as it is
              !! out.print(self.summary($text, $format));
        }

        my sub file-format(Str:D $plain --> Str:D) {
            my $f = try {
                my $p = run 'file', '-b', '-', :in, :out, :err;
                try $p.in.print($plain);
                try $p.in.close;
                $p.err.slurp(:close);
                $p.out.slurp(:close).split(',')[0].trim
            };
            $f || 'text'
        }

        my sub size(Int:D $bytes --> Str:D) {
            $bytes < 1000    ?? "$bytes B"
              !! $bytes < 1e6 ?? sprintf('%.1f kB', $bytes / 1e3)
              !! sprintf('%.1f MB', $bytes / 1e6)
        }

        # The first $width columns of $line, escapes kept, … when cut.
        my sub cut(Str:D $line, Int:D $width --> Str:D) {
            return $line if plain($line).chars <= $width;
            my $out  = '';
            my $cols = 0;
            my $pos  = 0;
            my $link = False;
            while $pos < $line.chars && $cols < $width - 1 {
                with $line.match($esc, :p($pos)) -> $m {
                    $out ~= ~$m;
                    $link = True if $m.starts-with("\e]8;");
                    $pos = $m.to;
                }
                else {
                    $out ~= $line.substr($pos, 1);
                    ++$cols;
                    ++$pos;
                }
            }
            $out ~ "…\e[0m" ~ ($link ?? "\e]8;;\e\\" !! '')
        }

        # Line 1, dimmed: format, lines, size. Line 2: the text from its
        # first line that is not blank, folded on one line, colors kept: each
        # line break is a dimmed \n, and the lines after the first lose their
        # indentation. It stops at 80 columns, or the terminal's width.
        method summary(Str:D $text, $format --> Str:D) {
            my $plain = plain($text);
            my $n     = $plain.lines.elems;
            my $width = min 80, terminal-size()[1];
            my @lines = $text.lines;
            my $from  = @lines.first({ plain($_).trim.chars }, :k) // 0;
            my $fold  = @lines[$from ..^ min(@lines.elems, $from + $width)]
              .map({ $++ ?? .subst(/^ \h+/, '') !! $_ })
              .join("\e[2m\\n\e[22m");
            "\e[2m{$format // file-format($plain)} · $n line{'s' if $n != 1}"
              ~ " · {size($plain.encode.bytes)}\e[0m\n"
              ~ cut($fold, $width) ~ "\e[0m\n"
        }
    }

    class REPL {
        also does REPL::Completions::Advanced;

        has Mu $.compiler;
        has Bool $!multi-line-enabled;
        has IO::Path $!history-file;

        has $!save_ctx;

        # Unique internal values for out-of-band eval results
        has $!need-more-input = {};
        has $!control-not-allowed = {};

        # The grammar / actions to use
        has $!grammar;
        has $!actions;

        # irak submission store: prompt number => source of the submission
        # made at that prompt, for the `!n` directive. Only the last
        # IRAK-KEEP prompt numbers are kept.
        has %!irak-sources;
        # irak: the last submission's output and its format, for `!p`.
        has $!irak-output;
        my constant IRAK-KEEP = 1000;

        # irak OSC 133 shell integration (semantic prompt marks): A before
        # the prompt, B after it, C before a submission's output, D;<status>
        # after it. Only with a line editor that tolerates escapes in the
        # prompt (Terminal::LineEditor), on a tty, unless
        # RAKUDO_DISABLE_OSC133 is set. See rak-plans/features/irak.md.
        has Bool $!osc133;          # emit marks in this session
        has Bool $!osc133-fresh;    # the prompt being read starts a submission
        has Bool $!osc133-output;   # C was sent for the current submission
        has Int  $!osc133-bytes;    # bytes of C, not output of the submission
        has      $!osc133-out;      # the terminal: irak points $*OUT at a page

        sub osc133(Str:D $mark --> Str:D) { "\e]133;$mark\e\\" }

        # The prompt to give the line editor: wrapped in A and B when it
        # starts a submission. Continuation prompts stay bare, so a
        # multi-line submission is one command.
        method osc133-prompt(Str:D $prompt --> Str:D) {
            $!osc133 && $!osc133-fresh
              ?? osc133('A') ~ $prompt ~ osc133('B')
              !! $prompt
        }

        # Send C once per submission, before its first output.
        method !osc133-output(--> Nil) {
            if $!osc133 && !$!osc133-output {
                $!osc133-output = True;
                my $before = $!osc133-out.tell;
                $!osc133-out.print: osc133('C');
                $!osc133-out.flush;
                # The REPL shows a value only when nothing was printed.
                $!osc133-bytes += $!osc133-out.tell - $before;
            }
        }

        # Close the submission with D and its status.
        method !osc133-done(Int:D $status --> Nil) {
            if $!osc133 {
                self!osc133-output;
                $!osc133-out.print: osc133("D;$status");
                $!osc133-out.flush;
            }
            $!osc133-output = False;
        }

        # irak: the REPL of the rak frontend (see GLOSSARY.md).
        sub irak(--> Bool:D) {
            so %*ENV<RAKUDO_RAK_FRONTEND> && %*ENV<RAKU_RAK_MODE>
        }

        # The irak banner: the rak repository and HEAD come from the build
        # config (tools/build/gen-rak-build-info.pl).
        sub irak-banner(--> Str:D) {
            my $config := nqp::gethllsym('default', 'SysConfig').rakudo-build-config;
            my str $url  = nqp::ifnull(nqp::atkey($config, 'rak-repo-url'), '');
            my str $head = nqp::ifnull(nqp::atkey($config, 'rak-head'), '');
            my $where = ($url, $head).grep(*.chars).join(' @ ');
            "Welcome to irak, the rak shell." ~ ($where ?? "\n$where" !! '')
        }

        # irak: the source of submission n when $line is exactly `!n`
        # (surrounding whitespace aside), else Nil. Used for `!n` TAB.
        method irak-recall(Str() $line) {
            irak() && $line ~~ /^ \s* '!' (\d+) \s* $/
              ?? %!irak-sources{+$0} // Nil
              !! Nil
        }

        # irak feedback (cognominal/rak#1): before running a submission,
        # irak shows how it reads it. irak-feedback compiles the submission
        # up to its parse, never running it, and returns:
        #   text        the submission with `my` inserted before each
        #               undeclared variable that can be declared
        #   spans       what each word denotes: Maps of from, to (offsets in
        #               text) and class: keyword, routine, command,
        #               naked-string or undeclared
        #   incomplete  True when the submission needs more lines
        # Only offsets from :$from on (the line being edited) get a `my`.
        # Compiling runs BEGIN-time code (BEGIN, use, constant): its output
        # is swallowed, so it does not garble the line being edited.

        # Spans whose first word is a keyword
        my constant IRAK-KEYWORD-NODES = <
          statement-control statement-prefix scope-declarator
          routine-declarator package-declarator multi-declarator
          statement-mod-cond statement-mod-loop sym
        >.Set;

        my class IrakSink is IO::Handle {
            submethod TWEAK { self.encoding: 'utf8' }
            method WRITE(|) { True }
            method opened(--> True) { }
            method t(--> False) { }
        }

        # Parse $code as the next submission would be: the Match, or the
        # exception that stopped the parse.
        method !irak-parse(Str:D $code) is raw {
            CATCH { default { return $_ } }
            CONTROL { when CX::Warn { .resume } }
            my $*OUT = IrakSink.new;
            my $*ERR = IrakSink.new;
            my $*GRAMMAR;
            my %adverbs = :target<parse>, :compunit_ok, :no-worries;
            if nqp::isconcrete($!save_ctx) {
                %adverbs<outer_ctx> := $!save_ctx;
                %adverbs<language_version> :=
                  Rakudo::Internals.LANGUAGE-VERSION-OF-CONTEXT($!save_ctx);
            }
            %adverbs<grammar> := $!grammar unless nqp::isnull($!grammar);
            %adverbs<actions> := $!actions unless nqp::isnull($!actions);
            $!compiler.compile($code, |%adverbs)
        }

        method !irak-keywords() {
            my $grammar := nqp::isnull($!grammar)
              ?? $!compiler.parsegrammar
              !! $!grammar;
            nqp::can($grammar, 'rak-keywords') ?? $grammar.rak-keywords !! {}
        }

        # Where the variable $name the parse stopped at ($pos) starts.
        sub irak-variable-start(Str:D $text, Str:D $name, $pos --> Int) {
            my int $at = ($pos // $text.chars) min $text.chars;
            $at = $at - $name.chars;
            while $at >= 0 {
                my $start := $text.rindex($name, $at);
                return Int unless $start.defined;
                return $start
                  unless $text.substr($start + $name.chars, 2)
                    ~~ /^ [ \w | <[-']> <.alpha> ] /;
                $at = $start - 1;
            }
            Int
        }

        sub irak-occurrences(Str:D $text, Str:D $name) {
            gather {
                my int $at;
                loop {
                    my $start := $text.index($name, $at);
                    last unless $start.defined;
                    take $start
                      unless $text.substr($start + $name.chars, 2)
                        ~~ /^ [ \w | <[-']> <.alpha> ] /;
                    $at = $start + $name.chars;
                }
            }
        }

        # The named children of a Match, and its positional ones: the
        # operands of a list infix (`,`, rak juxtaposition), keyed ''.
        sub irak-match-children(Mu $match) {
            my @children;
            for $match.list -> Mu $child {
                @children.push: '' => $child
                  if nqp::can($child, 'from') && $child.to > $child.from;
            }
            for $match.hash.kv -> $key, Mu $value {
                for nqp::istype($value, Positional) ?? $value.list !! ($value,) -> Mu $child {
                    @children.push: $key => $child
                      if nqp::can($child, 'from') && $child.to > $child.from;
                }
            }
            @children
        }

        # A redirection target is always a path.
        my constant IRAK-PATH-NODES = Map.new: (
          'redir-naked-filename', 1, 'redir-quoted-filename', 1,
          'redir-dquoted-filename', 1, 'redir-url', 1,
        );

        # A command argument is a path when it reads as one: absolute, from
        # home, `.`, `..`, or with a `/` in it. `data.txt` could be anything.
        sub irak-path-like(Str:D $word --> Bool:D) {
            so $word eq '.' | '..' | '~' || $word.starts-with('~/') || $word.contains('/')
        }

        # The spans of the words of a parsed submission, from its Match.
        sub irak-match-spans(Mu $root, Str:D $text, $keywords) {
            my @spans;
            my sub keywords-between(int $from, int $to, @skip) {
                for $text.substr($from, $to - $from).match(
                  / <.alpha> [ \w | <[-']> <.alpha> ]* /, :g) -> $word {
                    my int $start = $from + $word.from;
                    next if $start && $text.substr($start - 1, 1) ~~ / <[\w$@%&.^*!?:'-]> /;
                    next if @skip.first({ .value.from <= $start < .value.to });
                    @spans.push: ($start, $start + $word.chars, 'keyword')
                      if $keywords{~$word}:exists;
                }
            }
            # The Match tree has cycles: a signature's param-sep holds
            # itself. Each node is walked once.
            my %seen;
            my sub walk(Mu $node, Str:D $key, Str:D $parent) {
                return if %seen{nqp::objectid($node)}++;
                my @children = irak-match-children($node);
                my Mu $made := $node.made;
                my $name := nqp::isconcrete($made) ?? $made.^name !! '';
                if $key eq 'rak-command' {
                    with @children.first(*.key eq 'identifier') {
                        @spans.push: ($node.from, .value.to, 'command');
                    }
                }
                elsif $key eq 'identifier' && $parent eq 'RakuAST::QuotedString' {
                    @spans.push: ($node.from, $node.to, 'naked-string');
                }
                elsif $key eq 'longname' && $parent.starts-with('RakuAST::Call::Name') {
                    @spans.push: ($node.from, $node.to, 'routine');
                }
                elsif $key eq 'variable' | 'redir-var-filename'
                  # not a contextualizer, `$(…)` or `~(…)`
                  && $text.substr($node.from, $node.to - $node.from) !~~ /^ <[$@%&~#]> '(' / {
                    @spans.push: ($node.from, $node.to, 'variable');
                    return;
                }
                elsif IRAK-PATH-NODES{$key} {
                    @spans.push: ($node.from, $node.to, 'path');
                    return;
                }
                elsif $key eq 'literal'
                  && irak-path-like($text.substr($node.from, $node.to - $node.from)) {
                    @spans.push: ($node.from, $node.to, 'path');
                }
                keywords-between($node.from, $node.to, @children)
                  if IRAK-KEYWORD-NODES{$key};
                walk(.value, .key, $name) for @children;
            }
            walk($root, '', '');
            @spans
        }

        # When the parse fails, words can only be told apart from keywords.
        sub irak-keyword-spans(Str:D $text, $keywords) {
            gather for $text.match(/ <.alpha> [ \w | <[-']> <.alpha> ]* /, :g) -> $word {
                next if $word.from && $text.substr($word.from - 1, 1) ~~ / <[\w$@%&.^*!?:'-]> /;
                take ($word.from, $word.to, 'keyword') if $keywords{~$word}:exists;
            }
        }

        method irak-sgr(--> Map:D) { %irak-sgr.Map }

        # With :!declare, the text is only colored, never rewritten (the
        # highlighted cheat sheet shows its examples as written).
        method irak-feedback(Str() $submission, Int() :$from = 0, Bool:D :$declare = True --> Map:D) {
            my str $text = $submission;
            my @hidden;          # undeclared, declared only for the analysis
            my Mu $match := Nil;
            my Bool $incomplete = False;
            my int $prefix;

            # `my` goes before the first occurrence of an undeclared variable,
            # wherever it can stand. Whether it can is found by trying: the
            # insertion is undone (and the variable only hidden) when the
            # next round fails on something else than another undeclared
            # variable, or when the variable is still undeclared, as in a
            # string ("my $x" is then just text).
            my $tried;           # the last insertion: name, text before it
            # Each round declares, inserts or undoes for one variable, so the
            # rounds are bounded.
            for ^(2 * $text.comb(/<[$@%~#]>/).elems + 2) {
                my $declarations = @hidden.map({ "my $_;" }).join;
                $prefix = $declarations.chars;
                my $code = $declarations ~ $text ~ "\n";
                my Mu $result := self!irak-parse($code);
                unless nqp::istype($result, Exception) {
                    $match := $result;
                    last;
                }
                my $undeclared = $result ~~ X::Undeclared
                  && $result.symbol ~~ /^ <[$@%~#]> <.alpha> /;
                if $tried && (!$undeclared || $result.symbol eq $tried<name>) {
                    $text = $tried<text>;
                    @hidden.push: $tried<name>;
                    $tried = Nil;
                    next;
                }
                $tried = Nil;
                if $undeclared && !@hidden.grep(* eq $result.symbol) {
                    my $name  = $result.symbol;
                    my $start = irak-variable-start($text, $name,
                      $result.pos.defined ?? $result.pos - $prefix !! Nil);
                    if $declare && $start.defined && $start >= $from && !$result.suggestions {
                        $tried = { :$name, :$text };
                        $text = $text.substr(0, $start) ~ 'my ' ~ $text.substr($start);
                    }
                    else {
                        @hidden.push: $name;
                    }
                    next;
                }
                $incomplete = $!multi-line-enabled && wants-more-input($result, $code);
                last;
            }

            my $keywords := self!irak-keywords;
            my @spans = nqp::isconcrete($match)
              ?? irak-match-spans($match, $prefix ?? ' ' x $prefix ~ $text !! $text, $keywords)
                   .map({ (.[0] - $prefix, .[1] - $prefix, .[2]) }).grep(*.[0] >= 0)
              !! irak-keyword-spans($text, $keywords);
            for @hidden -> $name {
                for irak-occurrences($text, $name) -> $at {
                    # undeclared, rather than variable
                    @spans = @spans.grep({ !(.[0] == $at && .[2] eq 'variable') });
                    @spans.push: ($at, $at + $name.chars, 'undeclared');
                }
            }

            Map.new: (
              :$text,
              :spans(@spans.unique(:as(*.join(','))).sort(*.[0]).map({
                  Map.new: (:from(.[0]), :to(.[1]), :class(.[2]))
              }).List),
              :$incomplete,
              :parsed(so nqp::isconcrete($match)),
            )
        }

        # irak: what Enter does on the buffer $line, $before being the lines
        # of the submission already read (by default, those repl-loop has
        # read). True: finish the line as usual. Otherwise the feedback (see
        # irak-feedback) for the line alone: its text replaces the buffer,
        # which stays in the editor, colored by irak-colors. A second Enter
        # on that same text less than a second later finishes.
        has $!irak-enter-text;
        has $!irak-enter-time;
        has $!irak-colors;
        has Str $!irak-before = '';

        method irak-enter(Str() $line, Str() :$before = $!irak-before, :$now = now) {
            $!irak-colors = Nil;
            if $!irak-enter-time.defined && $line eq $!irak-enter-text
              && $now - $!irak-enter-time < 1 {
                $!irak-enter-time = Nil;
                return True;
            }
            $!irak-enter-time = Nil;
            return True if ($before ~ $line) ~~ /^ \s* $/
              || $before eq '' && $line ~~ /^ \s* '!'? '!' \d+ \s* $/;

            my $from = $before.chars;
            my %feedback = self.irak-feedback($before ~ $line, :$from);
            return True if %feedback<incomplete>;

            $!irak-enter-text = %feedback<text>.substr($from);
            $!irak-enter-time = $now;
            $!irak-colors = Map.new: (
              :text($!irak-enter-text),
              :spans(%feedback<spans>.grep(*<from> >= $from).map({
                  Map.new: (:from(.<from> - $from), :to(.<to> - $from), :class(.<class>))
              }).List),
            )
        }

        # irak: the feedback of the last Enter that did not finish (text and
        # spans), for the line editor to color its buffer while it holds
        # that text; Nil once a line is finished.
        method irak-colors() { $!irak-colors }

        # irak: the &on-finish callback of Terminal::LineEditor's prompt
        # (Enter), or Callable outside irak. An error in the analysis must
        # not lose the line: Enter then finishes as usual.
        method irak-on-finish() {
            return Callable unless irak();
            -> $buffer {
                my $enter = try self.irak-enter($buffer);
                $enter ~~ Map ?? $enter<text> !! True
            }
        }

        # irak topic: after a submission whose value is shown, $_ holds that
        # value, so the next submission can reach into it with a leading
        # dotty subscript. Assigns into the $_ the REPL's saved context sees.
        # The web log, @*IWEB: the requests a submission made, each with
        # the submission's number, source and value. It keeps the last 100,
        # or fewer when their JSON would exceed 10 MB.
        has @!iweb-size;
        method !log-web(Int:D $idx, Str:D $subm, Mu $output, $exception --> Nil) {
            my @taken = RAK-WEB-TAKE();
            return unless @taken;
            my $log := PROCESS::<@IWEB>;
            sub size(%e) {
                (try Rakudo::Internals::JSON.to-json(%e).encode.bytes) // %e.gist.encode.bytes
            }
            # the log was changed by hand: measure it again
            @!iweb-size = $log.map({ size($_) }) if @!iweb-size.elems != $log.elems;
            my $res := $exception.DEFINITE
              ?? $exception.message
              !! nqp::istype($output, Failure)
                ?? $output.exception.message
                !! (try Rakudo::Internals::RakFormat.format($output<>, :!color))
                     // $output.gist;
            for @taken -> %request {
                my %e = %request, :$idx, :$subm, :$res;
                $log.push: %e;
                @!iweb-size.push: size(%e);
            }
            while $log.elems > 100
              || ($log.elems > 1 && @!iweb-size.sum > 10_000_000) {
                $log.shift;
                @!iweb-size.shift;
            }
        }

        method !set-irak-topic(Mu $value --> Nil) {
            my $ctx := $!save_ctx;
            until nqp::isnull($ctx) || nqp::not_i(nqp::isconcrete($ctx)) {
                my $pad := nqp::ctxlexpad($ctx);
                if nqp::existskey($pad, '$_') {
                    my $topic := nqp::atkey($pad, '$_');
                    try $topic = $value;
                    return;
                }
                $ctx := nqp::ctxouterskipthunks($ctx);
            }
        }

        sub do-mixin($self, Str $module-name, $behavior, :@extra-modules,
                     Str :$fallback, Bool :$classlike) {
            my Bool $problem = False;
            try {
                CATCH {
                    when {
                        $_ ~~ X::CompUnit::UnsatisfiedDependency
                        and .specification.Str.contains: $module-name
                    } {
                        # ignore it
                    }
                    default {
                        say "I ran into a problem while trying to set up $module-name: $_";
                        if $fallback {
                            say "Falling back to $fallback (if present)";
                        }
                        $problem = True;
                    }
                }

                (require ::($_)) for @extra-modules;
                my $module = do require ::($module-name);
                my $who = $classlike ?? $module.WHO !! $module.WHO<EXPORT>.WHO<ALL>.WHO;
                my $new-self = $self but $behavior.^parameterize($who);
                $new-self.?init-line-editor();
                return ( $new-self, False );
            }

            ( Any, $problem )
        }

        sub mixin-readline($self, |c) {
            do-mixin($self, 'Readline', ReadlineBehavior, |c)
        }

        sub mixin-linenoise($self, |c) {
            do-mixin($self, 'Linenoise', LinenoiseBehavior, |c)
        }

        sub mixin-terminal-lineeditor($self, |c) {
            do-mixin($self, 'Terminal::LineEditor', TerminalLineEditorBehavior,
                     :extra-modules('Terminal::LineEditor::RawTerminalInput',),
                     :classlike, |c)
        }

        sub mixin-line-editor($self) {
            return $self but FallbackBehavior if  %*ENV<INSIDE_EMACS>;

            my %editor-to-mixin = (
                :Linenoise(&mixin-linenoise),
                :Readline(&mixin-readline),
                :LineEditor(&mixin-terminal-lineeditor),
                :none(-> $self { ( $self but FallbackBehavior, False ) }),
            );

            if %*ENV<RAKUDO_LINE_EDITOR> -> $line-editor {
                if !%editor-to-mixin{$line-editor} {
                    say "Unrecognized line editor '$line-editor'";
                    return $self but FallbackBehavior;
                }

                my $mixin = %editor-to-mixin{$line-editor};
                my ( $new-self, $problem ) = $mixin($self);
                return $new-self if $new-self;

                say "Could not find $line-editor module" unless $problem;
                return $self but FallbackBehavior;
            }

            # irak needs a line editor: Terminal::LineEditor first, since the
            # TAB / SHIFT-TAB navigation (rak-plans/features/irak.md) builds on it.
            if irak() {
                my ( $new-self, $problem ) = mixin-terminal-lineeditor($self, :fallback<Readline>);
                return $new-self if $new-self;
            }

            my ( $new-self, $problem ) = mixin-readline($self, :fallback<Linenoise>);
            return $new-self if $new-self;

            ( $new-self, $problem ) = mixin-linenoise($self, :fallback<LineEditor>);
            return $new-self if $new-self;

            ( $new-self, $problem ) = mixin-terminal-lineeditor($self);
            return $new-self if $new-self;

            if irak() {
                say "irak: no line editor, so no history or completion.\n"
                  ~ 'Install Terminal::LineEditor (`zef install --to=home Terminal::LineEditor`).'
                  ~ "\n"
                  unless %*ENV<_>:exists and %*ENV<_>.ends-with: 'rlwrap';
            }
            elsif $problem {
                say "Continuing without tab completions or line editor.\n";
                say 'You may want to consider installing `rlwrap` for simple line editor functionality.'
                  .naive-word-wrapper;
                say '';
            }
            elsif !Rakudo::Internals.IS-WIN
              && !( %*ENV<_>:exists and %*ENV<_>.ends-with: 'rlwrap' ) {
                say "No line editor found.\n";
                say 'You may want to exit first and `zef install Readline`, `zef install Linenoise`, or `zef install Terminal::LineEditor` or install `rlwrap` for a line editor before entering the REPL again.'
                  .naive-word-wrapper;
                say '';
            }

            $self but FallbackBehavior
        }

        method new(Mu \compiler, Mu \adverbs, $skip = %*ENV<RAKUDO_NO_VERSION>) {
            unless $skip {
                say irak()
                  ?? irak-banner()
                  !! compiler.version_string(
                       :shorten-versions,
                       :no-unicode(Rakudo::Internals.IS-WIN)
                     );
                say '';
            }

            my $multi-line-enabled = !%*ENV<RAKUDO_DISABLE_MULTILINE>;
            my $self = self.bless();
            $self.init(compiler, $multi-line-enabled);
            $self = mixin-line-editor($self);
            $self
        }

        method init(Mu \compiler, $multi-line-enabled --> Nil) {
            if compiler.repl-mode eq 'tty' && not $*IN.t {
                X::REPL::InvalidEnvironment.new(reason => "Unable to initialize REPL outside of a TTY").throw;
            }

            $!compiler := compiler;
            $!grammar  := nqp::null;
            $!actions  := nqp::null;
            $!multi-line-enabled = $multi-line-enabled;
            PROCESS::<$SCHEDULER>.uncaught_handler =  -> $exception {
                note "Uncaught exception on thread $*THREAD.id():\n" ~
                    $exception.gist.indent(4);
            }
        }

        method teardown {
            self.?teardown-line-editor;
        }

        # Calling this method is apparently being done by some ecosystem
        # modules, while this should really be considered an implementation
        # detail.  Keep the original state of the method for now, but
        # this should probably be DEPRECATED and/or given a properly
        # documented and tested API.
        method repl-eval($code, \exception, *%adverbs) {
            CATCH {
                when X::Syntax::Missing {
                    return $!need-more-input
                      if $!multi-line-enabled && .pos == $code.chars;
                    .throw;
                }

                when X::Comp::FailGoal {
                    return $!need-more-input
                      if $!multi-line-enabled && .pos == $code.chars;
                    .throw;
                }

                when X::ControlFlow::Return {
                    return $!control-not-allowed;
                }

                default {
                    exception = $_;
                    return;
                }
            }

            CONTROL {
                when CX::Emit | CX::Take { .rethrow; }
                when CX::Warn { .gist.say; .resume;  }
                return $!control-not-allowed;
            }

            self.compiler.eval($code, |%adverbs)
        }

        # Whether compiling $code died only because $code stops too early,
        # so that the REPL should read another line.
        sub wants-more-input(Exception:D $e, Str:D $code --> Bool:D) {
            if $e ~~ X::Syntax::Missing | X::Comp::FailGoal {
                return $e.pos == $code.chars;
            }
            if $e ~~ X::AdHoc {
                my str $message = $e.message;
                # Code that needs a heredoc while compiling dies the
                # same however much input follows.
                return $message eq 'Premature heredoc consumption' && $e !~~ X::Comp
                  || $message.starts-with('Ending delimiter ')
                  || $message.starts-with("Couldn't find terminator")
                  || $message.contains("is immediately followed by a combining codepoint");
            }
            False
        }

        method new-repl-eval($code, \exception, @*_, *%adverbs) {
            CATCH {
                when X::Syntax::Missing | X::Comp::FailGoal | X::AdHoc {
                    return $!need-more-input
                      if $!multi-line-enabled && wants-more-input($_, $code);
                    .throw;
                }

                when X::ControlFlow::Return {
                    return $!control-not-allowed;
                }

                default {
                    exception = $_;
                    return;
                }
            }

            CONTROL {
                when CX::Emit | CX::Take { .rethrow; }
                when CX::Warn { .gist.say; .resume;  }
                return $!control-not-allowed;
            }

            my $*GRAMMAR;
            %adverbs<grammar> := $!grammar unless nqp::isnull($!grammar);
            %adverbs<actions> := $!actions unless nqp::isnull($!actions);
            my $result := self.compiler.eval(
              $code.subst(/ '$*' \d+ /, { '@*_[' ~ $/.substr(2) ~ ']' }, :g),
              |%adverbs
            );

            # Grammar was changed, make sure we use changed one from now on
            if $*GRAMMAR -> $grammar {
                $!grammar := $grammar;
                $!actions := $grammar.actions;
            }

            $result
        }

        method interactive_prompt($index) { "[$index] > " }

        method get-effective-prompt($index, $code?) {
            my $prompt = %*ENV<PROMPT_INDICATOR>;
            if %*ENV<PROMPT_COMMAND> -> $cmd {
                try {
                    $prompt = self.compiler.eval($cmd, :outer_ctx($!save_ctx));
                    CATCH { default { } }
                }
            }
            if $code.defined && $code.chars {
                my $cont = %*ENV<PROMPT_MULTILINE_INDICATOR> // '* ';
                return $cont;
            }
            ($prompt // self.interactive_prompt($index)).Str
        }

        method repl-loop(:$no-exit, *%adverbs) {
            my int $stopped;     # did we press CTRL-c just now?
            my $previous-evals := IterationBuffer.new;  # previous values
            signal(SIGINT).tap: {
                # CTRL-c in the pager is the pager's
                unless IrakPage.paging {
                    exit if $stopped++;
                    say "Pressed CTRL-c, press CTRL-c again to exit";
                    print self.interactive_prompt($previous-evals.elems);
                }
            }

            say $no-exit
              ?? "Type 'exit' to leave"
              !! Rakudo::Internals.IS-WIN
                ?? "To exit type 'exit' or '^Z'"
                !! "To exit type 'exit' or '^D'";

            my $prompt;
            my $code;
            # irak: a submission starting with `- ` leaves $_ alone.
            my Bool $keep-topic;
            sub reset(--> Nil) {
                $code = '';
                $keep-topic = False;
                $prompt = self.interactive_prompt($previous-evals.elems);
            }
            reset;

            if irak() {
                RAK-WEB-ON();
                PROCESS::<@IWEB> := [];
            }

            $!osc133 = irak()
              && !%*ENV<RAKUDO_DISABLE_OSC133>
              && so(self.?osc133-capable)
              && $*IN.t && $*OUT.t;
            $!osc133-out := $*OUT;
            $!osc133-output = False;

            REPL: loop {
                # Why doesn't the catch-default in repl-eval catch all?
                CATCH {
                    default {
                        self!osc133-output;
                        say $_;
                        self!osc133-done(1);
                        reset
                    }
                }
                $!irak-before = $code;
                $!osc133-fresh = $code !~~ /\S/;
                my $newcode = self.repl-read(~$prompt);
                last if $no-exit and $newcode and $newcode eq 'exit';

                $stopped = 0;
                my $initial_out_position = $*OUT.tell;
                $!osc133-bytes = 0;
                my $status-before := RAK-STATUS();
                my $loaded-before := RAK-LOADED();

                # An undef $newcode implies ^D or similar
                if !$newcode.defined {
                    last;
                }

                # irak: `- ` before a fresh submission is stripped; the
                # submission then runs without making its value the topic.
                if irak() && $code eq '' && $newcode.starts-with('- ') {
                    $newcode .= substr(2);
                    $keep-topic = True;
                }

                # irak directives, only when they are the whole line of a
                # fresh submission: `!n` re-runs submission n's source,
                # `!!n` sets $_ to submission n's value.
                # `!p` pages the last output again.
                if irak() && $code eq '' && $newcode ~~ /^ \s* '!p' \s* $/ {
                    self!osc133-output;
                    my int $status = 0;
                    if !IrakPage.command {
                        say "irak: paging is off";
                        $status = 1;
                    }
                    orwith $!irak-output {
                        $*OUT.t
                          ?? IrakPage.page(.key, .value, $*OUT)
                          !! print .key;
                    }
                    else {
                        say "irak: no output to page";
                        $status = 1;
                    }
                    $keep-topic = False;
                    self!osc133-done($status);
                    next;
                }

                if irak() && $code eq ''
                  && $newcode ~~ /^ \s* ('!'?) '!' (\d+) \s* $/ {
                    my $n = +$1;
                    if $0.chars {
                        if $n < $previous-evals.elems {
                            self!set-irak-topic($previous-evals[$n]);
                            self!osc133-done(0);
                        }
                        else {
                            self!osc133-output;
                            say "irak: no value for submission $n";
                            self!osc133-done(1);
                        }
                        $keep-topic = False;
                        next;
                    }
                    with %!irak-sources{$n} {
                        self!osc133-output;
                        say $_;
                        $newcode = $_;
                        if $newcode.starts-with('- ') {
                            $newcode .= substr(2);
                            $keep-topic = True;
                        }
                        # The echo is not output of the re-run code.
                        $initial_out_position = $*OUT.tell;
                        $!osc133-bytes = 0;
                    }
                    else {
                        self!osc133-output;
                        say "irak: no submission $n";
                        $keep-topic = False;
                        self!osc133-done(1);
                        next;
                    }
                }

                $code = $code ~ $newcode ~ "\n";

                if $code ~~ /^ <.ws> $/ {
                    next;
                }

                my $*CTXSAVE := self;
                my $*MAIN_CTX;
                RAK-WEB-TAKE();    # requests of an aborted submission

                # irak holds what the submission prints, to page it.
                my $tty  := $*OUT;
                my $page := irak() ?? IrakPage.for($tty) !! Nil;
                my $exception;
                my $output is default(Nil) = do {
                    # an escaping exception is reported on the terminal
                    CATCH { default { $page.end if $page; .rethrow } }
                    my $*OUT = $page // $tty;
                    self.new-repl-eval(
                      $code,
                      $exception,
                      $previous-evals.List,
                      :outer_ctx($!save_ctx),
                      # the revision of the saved context, not the compiler's
                      :language_version(
                        Rakudo::Internals.LANGUAGE-VERSION-OF-CONTEXT($!save_ctx)
                      ),
                      |%adverbs)
                }

                if self.input-incomplete($output) {
                    .end with $page;
                    $prompt = '* ';
                    next;
                }

                # The submission is complete. C normally went out from
                # ctxsave, when its code started running; a compile error
                # never runs, so send C before showing it.
                self!osc133-output;

                if self.input-toplevel-control($output) {
                    .end with $page;
                    say "Control flow commands not allowed in toplevel";
                    self!osc133-done(1);
                    reset;
                    next;
                }

                if $*MAIN_CTX {
                    $!save_ctx := $*MAIN_CTX;
                }

                # Hyper/Race may confuse the output checker, make sure
                # they've completed running before doing anything else
                $output.sink if nqp::istype($output,ParallelSequence);
                if irak() {
                    my $n = $previous-evals.elems;
                    %!irak-sources{$n} = ($keep-topic ?? '- ' !! '') ~ $code.chomp;
                    %!irak-sources{$n - IRAK-KEEP}:delete;
                    self!log-web($n, %!irak-sources{$n}, $output, $exception);
                }

                # Print the result if:
                # - there wasn't some other output
                # - the result is an *unhandled* Failure
                # - print an exception if one had occured
                # irak pages long output, then shows errors in full.
                my $format;
                if $exception.DEFINITE {
                    .end with $page;
                    self.repl-print($exception);
                }
                elsif irak() && nqp::istype($output, Rakudo::Internals::RakProc) {
                    # a command's Proc prints nothing and leaves $_ alone
                }
                elsif irak() && nqp::istype($output, Rakudo::Internals::RakFormatted) {
                    # the formatter shows its JSON and leaves $_ alone
                    $format = 'JSON';
                    my $*OUT = $page // $tty;
                    $output.show;
                }
                elsif irak() && $initial_out_position + $!osc133-bytes == $*OUT.tell
                  && !($page && $page.wrote)
                  && nqp::not_i(nqp::eqaddr(RAK-LOADED(), $loaded-before))
                  && nqp::eqaddr($output<>, RAK-LOADED()) {
                    # a load of JSON shows it as the formatter does
                    $format = 'JSON';
                    {
                        my $*OUT = $page // $tty;
                        print Rakudo::Internals::RakFormat.format(
                          $output<>, :color(?(try $*OUT.t))) ~ "\n";
                    }
                    $previous-evals.push: $output<>;
                    self!set-irak-topic($output<>) unless $keep-topic;
                }
                elsif nqp::istype($output, Failure) and not $output.handled {
                    .end with $page;
                    self.repl-print($output);
                    $previous-evals.push: $output<>;
                }
                elsif $initial_out_position + $!osc133-bytes == $*OUT.tell
                    && !($page && $page.wrote) {
                    $format = $output.^name;
                    {
                        my $*OUT = $page // $tty;
                        self.repl-print($output);
                    }
                    $previous-evals.push: $output<>;
                    self!set-irak-topic($output<>)
                      if irak() && !$keep-topic
                      && nqp::not_i(nqp::eqaddr($output<>, Nil));
                }
                with $page {
                    .end(:$format);
                    $!irak-output = .text => $format if .wrote;
                }

                # irak shows a non-zero exit status of the last command, dimmed.
                my int $command-exit;
                my Bool $failed = so $exception.DEFINITE
                  || (nqp::istype($output, Failure) && !$output.handled);
                if irak() {
                    my $status := RAK-STATUS();
                    if $status.DEFINITE
                      && nqp::not_i(nqp::eqaddr($status, $status-before))
                      && $status.exitcode {
                        $command-exit = $status.exitcode;
                        say $*OUT.t
                          ?? "\e[2mexit $command-exit\e[0m"
                          !! "exit $command-exit";
                    }
                }


                # D's status: a failed command's exit status, else 1 when
                # the submission threw or returned an unhandled Failure.
                self!osc133-done($command-exit || ($failed ?? 1 !! 0));
                reset;
            }

            self.teardown;
        }

        # This appears to be a magic method that is called somewhere inside
        # the compiler.  The semantics of $*MAIN_CTX and $*CTXSAVE appear
        # to be needed to get a persistency with regards to scope between
        # lines entered in the REPL.
        method ctxsave(--> Nil) {
            $*MAIN_CTX := nqp::ctxcaller(nqp::ctx());
            $*CTXSAVE := 0;
            # The submission parsed and its code starts running now: its
            # output follows. An incomplete submission never gets here.
            self!osc133-output;
        }

        method save-ctx() { $!save_ctx }

        method input-incomplete(Mu $value --> Bool:D) {
            nqp::hllbool(nqp::can($value, 'WHERE'))
              and $value.WHERE == $!need-more-input.WHERE
        }

        method input-toplevel-control(Mu $value --> Bool:D) {
            nqp::hllbool(nqp::can($value, 'WHERE'))
              and $value.WHERE == $!control-not-allowed.WHERE
        }

        method repl-print(Mu $value --> Nil) {
            my $method := %*ENV<RAKU_REPL_OUTPUT_METHOD> // "gist";
            CATCH {
                default { say ."$method"() }
            }
            if nqp::can($value,$method) {
                if nqp::istype($value,List) && $value.are(Match) {
                    say ."$method"() for $value<>;
                }
                else {
                    say $value."$method"();
                }
            }
            else {
                say "(low-level object `$value.^name()`)";
            }
        }

        method history-file(--> Str:D) {
            without $!history-file {
                if %*ENV<RAKUDO_HIST> -> $history-file {
                    $!history-file = $history-file.IO;
                }
                else {
                    my $dir := $*HOME || $*TMPDIR;
                    my $old := $dir.add('.perl6/rakudo-history');
                    # irak lines are rak, not Raku: keep them apart.
                    my $new := $dir.add(irak() ?? '.raku/irak-history' !! '.raku/rakudo-history');
                    if !irak() && $old.e && !$new.e {  # migrate old hist to new location
                        $new.spurt($old.slurp);
                        $old.unlink;
                    }
                    $!history-file = $new;
                }

                without mkdir $!history-file.parent {
                    note "I ran into a problem trying to set up history: {.exception.message}";
                    note 'Sorry, but history will not be saved at the end of your session';
                }
            }

            # make sure there is a history file
            $!history-file.open(:a).close unless $!history-file.e;

            $!history-file.absolute
        }
    }
}

sub repl(*%_) {
    my $repl := REPL.new(nqp::getcomp("Raku"), %_, True);
    nqp::bindattr($repl,REPL,'$!save_ctx',nqp::ctxcaller(nqp::ctx));

    $repl.repl-loop(:no-exit);
}

# vim: expandtab shiftwidth=4
