use Test;

# irak paging (PLANS/features/paging.md): output longer than 5 lines goes to
# the pager, then a two-line summary stays at the prompt. `!p` pages the
# last output again.
#
# The REPL needs a tty, so each session runs under script(1), without a line
# editor. The pager is a shell command that appends what it gets to a file.

my $script = run(<sh -c>, 'command -v script', :out, :err).out.slurp(:close).trim;
plan :skip-all('script(1) is needed to give the REPL a tty') unless $script;

plan 13;

my $paged = $*TMPDIR.add("irak-paged-$*PID.txt");

sub session(*@lines, :$pager) {
    my %env = %*ENV;
    %env<RAKUDO_LINE_EDITOR>  = 'none';
    %env<RAKUDO_RAK_FRONTEND> = 1;
    %env<RAKU_RAK_MODE>       = 1;
    %env<PAGER>:delete;
    %env<RAK_PAGER> = $pager;
    my $feed = 'sleep 2; '
      ~ @lines.map({ "printf '%s\\r' '$_'; sleep 1; " }).join
      ~ "sleep 2; printf 'exit\\r'; sleep 0.5";
    my $cmd = "($feed) | '$script' -qec '{$*EXECUTABLE.absolute}' /dev/null";
    run(<sh -c>, $cmd, :out, :err, :%env).out.slurp(:close).subst("\r", '', :g)
}

my $out = session :pager("cat >> '$paged'; echo PAGED >> '$paged'"),
  'for ^8 { say $_ }',
  '!p',
  'say "short"',
  '$_ = { a => [1, 2] }; .',
  'say 1; say 2; die "boom"',
  'for ^6 { say $_; sleep 0.3 }';
my $pager = $paged.e ?? $paged.slurp !! '';
$paged.unlink;

ok   $pager.starts-with("0\n1\n2\n3\n4\n5\n6\n7\nPAGED\n"), 'long output goes to the pager';
like $out, /"\e[2m" <-[·]>+ ' · 8 lines · 16 B' "\e[0m\n" '0'/,
  'then a summary: format, lines, size, and the first line';
like $out, /"\e[0m\n0\e[2m\\n\e[22m1\e[2m\\n\e[22m2" .*? "7\e[0m\n"/,
  'the summary folds the lines on one, each break a dimmed \\n';
like $out, /"\e[2mJSON · " \d+ ' lines' .*? \n <-[\n]>* '{' "\e[0m\e[2m\\n\e[22m" \e '[' <[0..9;]>+ 'm"a"'/,
  'the folded summary of JSON keeps its colors';
like $out, /'say "short"' \n 'short' \n/, 'short output is shown as it is';
is   $pager.comb('PAGED').elems, 3, '!p and the formatter page too';
like $out, /'!p' \n "\e[2m" <-[·]>+ ' · 8 lines'/, '!p shows the summary again';
like $out, /"\e[2mJSON · " \d+ ' lines'/, "the formatter's format is JSON";
like $out, /'die "boom"' \n '1' \n '2' \n 'boom'/, 'an error comes after the output, unpaged';
like $out, /'sleep 0.3 }' \n '0' \n '1' \n '2' \n '3' \n '4' \n '5' \n/,
  'output still coming after 1 s is let through, unpaged';
nok  $out.contains('SORRY'), 'no compile errors';

$out = session :pager(''), 'for ^8 { say $_ }', '!p';
like $out, /'for ^8 { say $_ }' \n '0' \n [\d \n]+ '7' \n/,
  'an empty RAK_PAGER turns paging off';
like $out, /'!p' \n 'irak: paging is off'/, '!p says paging is off';
