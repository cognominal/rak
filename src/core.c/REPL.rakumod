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

    my role TerminalLineEditorBehavior[$WHO] {
        my $cli-input = $WHO<CLIInput>;
        my $cli;

        method completions-for-line(Str $line, int $cursor-index) { ... }

        method history-file(--> Str:D) { ... }

        # irak: the input field colors each word of its buffer as the last
        # Enter read it (irak-colors), while the buffer holds that text.
        my %irak-sgr =
          keyword        => "\e[1;35m",
          routine        => "\e[36m",
          command        => "\e[1;32m",
          naked-string   => "\e[33m",
          undeclared     => "\e[4;31m",
        ;

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
            $cli = self.irak-on-finish
              ?? $cli-input.new(:&get-completions, :input-class(irak-input-class(self)))
              !! $cli-input.new(:&get-completions);
            $cli.load-history($.history-file);
        }

        method teardown-line-editor {
            $cli.save-history($.history-file);
        }

        method repl-read(Mu \prompt) {
            self.update-completions;
            my $line = $cli.prompt(prompt.chop, :on-finish(self.irak-on-finish));

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
        my constant IRAK-KEEP = 1000;

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

        sub irak-match-children(Mu $match) {
            my @children;
            for $match.hash.kv -> $key, Mu $value {
                for nqp::istype($value, Positional) ?? $value.list !! ($value,) -> Mu $child {
                    @children.push: $key => $child
                      if nqp::can($child, 'from') && $child.to > $child.from;
                }
            }
            @children
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
            my sub walk(Mu $node, Str:D $key, Str:D $parent) {
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

        method irak-feedback(Str() $submission, Int() :$from = 0 --> Map:D) {
            my str $text = $submission;
            my @hidden;          # undeclared, declared only for the analysis
            my Mu $match := Nil;
            my Bool $incomplete = False;
            my int $prefix;

            # Each round declares one variable, so the rounds are bounded.
            for ^($text.comb(/<[$@%]>/).elems + 2) {
                my $declarations = @hidden.map({ "my $_;" }).join;
                $prefix = $declarations.chars;
                my $code = $declarations ~ $text ~ "\n";
                my Mu $result := self!irak-parse($code);
                unless nqp::istype($result, Exception) {
                    $match := $result;
                    last;
                }
                if $result ~~ X::Undeclared
                  && $result.symbol ~~ /^ <[$@%]> <.alpha> /
                  && !@hidden.grep(* eq $result.symbol) {
                    my $name  = $result.symbol;
                    my $start = irak-variable-start($text, $name,
                      $result.pos.defined ?? $result.pos - $prefix !! Nil);
                    if $start.defined && $start >= $from
                      && !$result.suggestions
                      && $text.substr($start + $name.chars)
                           ~~ /^ \h* [ ':=' | '=' <!before <[=>]> | ':='> ] / {
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
                @spans.push: ($_, $_ + $name.chars, 'undeclared')
                  for irak-occurrences($text, $name);
            }

            Map.new: (
              :$text,
              :spans(@spans.unique(:as(*.join(','))).sort(*.[0]).map({
                  Map.new: (:from(.[0]), :to(.[1]), :class(.[2]))
              }).List),
              :$incomplete,
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
            # TAB / SHIFT-TAB navigation (PLANS/features/irak.md) builds on it.
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
                return $message eq 'Premature heredoc consumption'
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
                exit if $stopped++;
                say "Pressed CTRL-c, press CTRL-c again to exit";
                print self.interactive_prompt($previous-evals.elems);
            }

            say $no-exit
              ?? "Type 'exit' to leave"
              !! Rakudo::Internals.IS-WIN
                ?? "To exit type 'exit' or '^Z'"
                !! "To exit type 'exit' or '^D'";

            my $prompt;
            my $code;
            sub reset(--> Nil) {
                $code = '';
                $prompt = self.interactive_prompt($previous-evals.elems);
            }
            reset;

            REPL: loop {
                # Why doesn't the catch-default in repl-eval catch all?
                CATCH {
                    default { say $_; reset }
                }
                $!irak-before = $code;
                my $newcode = self.repl-read(~$prompt);
                last if $no-exit and $newcode and $newcode eq 'exit';

                $stopped = 0;
                my $initial_out_position = $*OUT.tell;
                my $status-before := RAK-STATUS();

                # An undef $newcode implies ^D or similar
                if !$newcode.defined {
                    last;
                }

                # irak directives, only when they are the whole line of a
                # fresh submission: `!n` re-runs submission n's source,
                # `!!n` sets $_ to submission n's value.
                if irak() && $code eq ''
                  && $newcode ~~ /^ \s* ('!'?) '!' (\d+) \s* $/ {
                    my $n = +$1;
                    if $0.chars {
                        if $n < $previous-evals.elems {
                            self!set-irak-topic($previous-evals[$n]);
                        }
                        else {
                            say "irak: no value for submission $n";
                        }
                        next;
                    }
                    with %!irak-sources{$n} {
                        say $_;
                        $newcode = $_;
                        # The echo is not output of the re-run code.
                        $initial_out_position = $*OUT.tell;
                    }
                    else {
                        say "irak: no submission $n";
                        next;
                    }
                }

                $code = $code ~ $newcode ~ "\n";

                if $code ~~ /^ <.ws> $/ {
                    next;
                }

                my $*CTXSAVE := self;
                my $*MAIN_CTX;

                my $output is default(Nil) = self.new-repl-eval(
                    $code,
                    my $exception,
                    $previous-evals.List,
                    :outer_ctx($!save_ctx),
                    # the revision of the saved context, not the compiler's
                    :language_version(
                      Rakudo::Internals.LANGUAGE-VERSION-OF-CONTEXT($!save_ctx)
                    ),
                    |%adverbs);

                if self.input-incomplete($output) {
                    $prompt = '* ';
                    next;
                }

                if self.input-toplevel-control($output) {
                    say "Control flow commands not allowed in toplevel";
                    reset;
                    next;
                }

                if $*MAIN_CTX {
                    $!save_ctx := $*MAIN_CTX;
                }

                if irak() {
                    my $n = $previous-evals.elems;
                    %!irak-sources{$n} = $code.chomp;
                    %!irak-sources{$n - IRAK-KEEP}:delete;
                }

                # Print the result if:
                # - there wasn't some other output
                # - the result is an *unhandled* Failure
                # - print an exception if one had occured
                # irak shows a non-zero exit status of the last command, dimmed.
                if irak() {
                    my $status := RAK-STATUS();
                    if $status.DEFINITE
                      && nqp::not_i(nqp::eqaddr($status, $status-before))
                      && $status.exitcode {
                        say $*OUT.t
                          ?? "\e[2mexit {$status.exitcode}\e[0m"
                          !! "exit {$status.exitcode}";
                    }
                }

                if $exception.DEFINITE {
                    self.repl-print($exception);
                }
                elsif irak() && nqp::istype($output, Rakudo::Internals::RakProc) {
                    # a command's Proc prints nothing and leaves $_ alone
                }
                elsif $initial_out_position == $*OUT.tell
                    or nqp::istype($output, Failure) and not $output.handled {
                    self.repl-print($output);
                    $previous-evals.push: $output<>;
                    self!set-irak-topic($output<>)
                      if irak()
                      && nqp::not_i(nqp::istype($output, Failure))
                      && nqp::not_i(nqp::eqaddr($output<>, Nil));
                }
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
