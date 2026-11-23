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

    my role TerminalLineEditorBehavior[$WHO] {
        my $cli-input = $WHO<CLIInput>;
        my $cli;

        method completions-for-line(Str $line, int $cursor-index) { ... }

        method history-file(--> Str:D) { ... }

        method init-line-editor {
            my sub get-completions($contents, $pos) {
                # irak: `!n` TAB puts submission n's source in the buffer.
                with self.irak-recall($contents) { return ($_,) }
                eager self.completions-for-line($contents, $pos)
            }
            # The role goes in before .new: the object starts its input
            # threads as it is built.
            my $irak := so %*ENV<RAKUDO_RAK_FRONTEND> && %*ENV<RAKU_RAK_MODE>;
            $cli = ($irak ?? $cli-input.^mixin(IrakResize) !! $cli-input)
              .new(:&get-completions);
            $cli.bind-key('Resize', 'resize') if $irak;
            $cli.load-history($.history-file);
        }

        method teardown-line-editor {
            $cli.save-history($.history-file);
        }

        method repl-read(Mu \prompt) {
            self.update-completions;
            my $line = $cli.prompt(prompt.chop);

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

    # irak paging (PLANS/features/paging.md): $*OUT during a submission. It
    # holds what the submission prints, so irak can measure it and page it,
    # until the submission has run 1 s or flushes; from then on it lets the
    # output through. It keeps a copy of everything for `!p`.
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
            $!timer := $*SCHEDULER.cue({ self.release }, :in(1));
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
            $!timer.cancel;
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

        # Line 1, dimmed: format, lines, size. Line 2: the start of the
        # first line that is not blank.
        method summary(Str:D $text, $format --> Str:D) {
            my $plain = plain($text);
            my $n     = $plain.lines.elems;
            my $first = $text.lines.first({ plain($_).trim.chars }) // '';
            "\e[2m{$format // file-format($plain)} · $n line{'s' if $n != 1}"
              ~ " · {size($plain.encode.bytes)}\e[0m\n"
              ~ cut($first, 80) ~ "\e[0m\n"
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

        method new-repl-eval($code, \exception, @*_, *%adverbs) {
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

                when X::AdHoc {
                    my str $message = .message;
                    if $message eq 'Premature heredoc consumption'
                      || $message.starts-with('Ending delimiter ')
                      || $message.starts-with("Couldn't find terminator")
                      || $message.contains("is immediately followed by a combining codepoint") {
                        return $!need-more-input
                          if $!multi-line-enabled;
                    }
                    .throw
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

            REPL: loop {
                # Why doesn't the catch-default in repl-eval catch all?
                CATCH {
                    default { say $_; reset }
                }
                my $newcode = self.repl-read(~$prompt);
                last if $no-exit and $newcode and $newcode eq 'exit';

                $stopped = 0;
                my $initial_out_position = $*OUT.tell;
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
                    if !IrakPage.command {
                        say "irak: paging is off";
                    }
                    orwith $!irak-output {
                        $*OUT.t
                          ?? IrakPage.page(.key, .value, $*OUT)
                          !! print .key;
                    }
                    else {
                        say "irak: no output to page";
                    }
                    $keep-topic = False;
                    next;
                }

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
                        $keep-topic = False;
                        next;
                    }
                    with %!irak-sources{$n} {
                        say $_;
                        $newcode = $_;
                        if $newcode.starts-with('- ') {
                            $newcode .= substr(2);
                            $keep-topic = True;
                        }
                        # The echo is not output of the re-run code.
                        $initial_out_position = $*OUT.tell;
                    }
                    else {
                        say "irak: no submission $n";
                        $keep-topic = False;
                        next;
                    }
                }

                $code = $code ~ $newcode ~ "\n";

                if $code ~~ /^ <.ws> $/ {
                    next;
                }

                my $*CTXSAVE := self;
                my $*MAIN_CTX;

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

                if self.input-toplevel-control($output) {
                    .end with $page;
                    say "Control flow commands not allowed in toplevel";
                    reset;
                    next;
                }

                if $*MAIN_CTX {
                    $!save_ctx := $*MAIN_CTX;
                }

                if irak() {
                    my $n = $previous-evals.elems;
                    %!irak-sources{$n} = ($keep-topic ?? '- ' !! '') ~ $code.chomp;
                    %!irak-sources{$n - IRAK-KEEP}:delete;
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
                elsif irak() && $initial_out_position == $*OUT.tell
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
                elsif $initial_out_position == $*OUT.tell
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
