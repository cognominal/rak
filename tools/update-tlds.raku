# Refresh the TLD list that decides which naked load targets are bare hosts
# (PLANS/features/url-targets.md). It rewrites the block between the
# `BEGIN TLDS` and `END TLDS` lines of src/Rak/Grammar.nqp from IANA's list
# of root-zone TLDs, downloaded with curl unless a saved copy is given.
#
#   raku tools/update-tlds.raku [tlds-alpha-by-domain.txt]

sub MAIN(Str $file?) {
    my $text = $file
      ?? $file.IO.slurp
      !! run(<curl -sfL https://data.iana.org/TLD/tlds-alpha-by-domain.txt>, :out).out.slurp(:close);
    my ($version) = $text.lines.grep(*.starts-with('#'));
    my @tlds = $text.lines.grep({ .chars && !.starts-with('#') })>>.lc.sort;
    die "No TLDs found" unless @tlds > 1000;

    my @rows;
    my $row = '';
    for @tlds -> $t {
        if $row.chars + $t.chars > 70 {
            @rows.push: $row;
            $row = '';
        }
        $row ~= "$t ";
    }
    @rows.push: $row if $row;

    my $grammar = 'src/Rak/Grammar.nqp'.IO;
    my $src = $grammar.slurp;
    # The block takes the indentation of its BEGIN TLDS marker.
    my $in = ($src ~~ / ^^ (\h*) '# BEGIN TLDS' /) ?? ~$0 !! '';
    my $block = "$in# $version.substr(2)\n"
      ~ "$in# {+@tlds} TLDs from https://data.iana.org/TLD/tlds-alpha-by-domain.txt\n"
      ~ "{$in}my str \$tlds :=\n"
      ~ @rows.map({ "$in    '$_'" }).join(" ~\n") ~ ";\n";
    $src ~~ s/ (^^ \h* '# BEGIN TLDS' \h* \n) .*? (^^ \h* '# END TLDS' \h* $$) /$0$block$1/
      or die "No BEGIN TLDS / END TLDS block in $grammar";
    $grammar.spurt: $src;
    say "{+@tlds} TLDs written to $grammar";
}
