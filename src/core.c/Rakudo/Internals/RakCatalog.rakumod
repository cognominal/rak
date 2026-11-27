# The command catalog (rak-plans/features/command-catalog.md): the formats
# external commands read on their standard input and emit on their standard
# output. Rak ships the defaults below; a user's commands.yaml in rak's config
# folder is merged over them, and the result is $*RAK-CONFIG.commands.

my class Rakudo::Internals::RakCatalog is implementation-detail {

    # A heredoc would need Str.indent while the setting is compiled.
    my constant DEFAULTS = (
      'jq: &jq',
      '  reads: [jsonl, json]',
      '  emits: json',
      '  bundling: true',
      '  flags:',
      '    -c: {emits: jsonl}',
      '    --compact-output: {emits: jsonl}',
      '    -r: {emits: lines}',
      '    --raw-output: {emits: lines}',
      '    -j: {emits: text}',
      '    --join-output: {emits: text}',
      'jaq: *jq',
      'gojq: *jq',
      'yq:',
      '  reads: [yaml]',
      '  emits: yaml',
      '  flags:',
      '    -o json: {emits: json}',
      '    -o yaml: {emits: yaml}',
      '    --output-format json: {emits: json}',
      '    --output-format yaml: {emits: yaml}',
      'gh api: {emits: json, flags: {-i: {emits: text}, --include: {emits: text}}}',
      'kubectl get:',
      '  flags:',
      '    -o json: {emits: json}',
      '    -o yaml: {emits: yaml}',
      '    --output json: {emits: json}',
      '    --output yaml: {emits: yaml}',
      'docker inspect: {emits: json}',
      'jc: {emits: json}',
      'gron: {reads: [json], emits: lines}',
      'fx: {reads: [json]}',
    ).join("\n") ~ "\n";

    my constant READS = ('lines', 'yaml');

    # The shipped entries, then the user's commands.yaml over them: a user's
    # entry replaces the shipped one of the same name. A broken file is
    # reported and ignored.
    method load() {
        my $c := Rakudo::Internals::RakYAML.decode(DEFAULTS, 'command catalog');
        my $file := RAK-XDG-DIR('config').add('commands.yaml');
        if $file.f {
            my $user := try Rakudo::Internals::RakYAML.decode($file.slurp, ~$file);
            if $! {
                note $!.message ~ ' (the command catalog ignores it)';
            }
            elsif nqp::istype($user, Associative) {
                $c{.key} = .value for $user.pairs;
            }
            elsif nqp::isconcrete($user) {
                note "$file: the command catalog must be a mapping (ignored)";
            }
        }
        $c
    }

    my $defaults;
    method commands() {
        my $c := Rakudo::Internals::RakTable.setting('commands');
        nqp::istype($c, Associative) ?? $c !! ($defaults //= self.load)
    }

    my sub formats(Mu \f) {
        nqp::istype(f, Positional) ?? f.map(*.Str).List !! (f.Str,)
    }

    # What the command reads and emits: `reads` a list of formats, `emits`
    # one. An entry of two words (`gh api`) matches the command and its first
    # argument before the command alone. Flags given change both, the later
    # in the entry winning; `--x=y` is `--x y`, and `-rc` is `-r -c` for an
    # entry with `bundling: true`.
    method caps(Str:D $name, @args) {
        my $commands := self.commands;
        my $base := $name.IO.basename;
        my $entry := @args && $commands.AT-KEY("$base @args[0]") // Nil;
        $entry := $commands.AT-KEY($base) // Nil
          unless nqp::istype($entry, Associative);
        return Map.new((:reads(READS), :emits<lines>))
          unless nqp::istype($entry, Associative);
        my $reads := $entry<reads>.defined ?? formats($entry<reads>) !! READS;
        my $emits := $entry<emits>.defined ?? $entry<emits>.Str !! 'lines';
        my $flags := $entry<flags>;
        if nqp::istype($flags, Associative) {
            my @a;
            for @args.map(*.Str) -> $arg {
                if $arg.starts-with('-') && $arg.contains('=') {
                    @a.append: $arg.split('=', 2);
                }
                elsif $entry<bundling> && $arg ~~ /^ '-' <[a..zA..Z]> ** 2..* $/ {
                    @a.append: $arg.substr(1).comb.map('-' ~ *);
                }
                else {
                    @a.push: $arg;
                }
            }
            # The flags given, as the entry spells them; they apply in the
            # entry's order, so the later one wins (`jq -rc` emits lines).
            my %given;
            for @a.kv -> $i, $arg {
                %given{"$arg @a[$i + 1]"} = True if $i < @a.end;
                %given{$arg} = True;
            }
            for $flags.pairs -> $p {
                my $f := $p.value;
                next unless %given{$p.key} && nqp::istype($f, Associative);
                $reads := formats($f<reads>) if $f<reads>.defined;
                $emits := $f<emits>.Str      if $f<emits>.defined;
            }
        }
        Map.new((:$reads, :$emits))
    }
}

# vim: expandtab shiftwidth=4
