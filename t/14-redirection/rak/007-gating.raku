use Test;

plan 4;

# ---------------------------------------------------------------------------
# Gating test: a .raku file must NOT interpret `>` as redirection.
# Running this with `raku` uses traditional Raku semantics, so `>`
# is a comparison operator, never a redirection (no file is created).
# ---------------------------------------------------------------------------

# 1. In .raku mode, `say foo >output_raku.txt` is a normal (attempted)
#    comparison — `foo` is an undeclared bareword call, which is a
#    compile-time error under both frontends. Probe through EVAL and
#    verify no output file was ever created.
{
    try { EVAL 'say foo >output_raku.txt;' }
    nok 'output_raku.txt'.IO.e,
        '1: .raku file does not interpret > as output redirection';
    'output_raku.txt'.IO.unlink if 'output_raku.txt'.IO.e;
}

# 2. Even with quotes, `> 'output_raku2.txt'` has a space after `>`, so it
#    is a comparison, not a redirection — in traditional Raku it can never
#    write a file (the string comparison itself fails).
{
    try { EVAL 'my $r = "hello" > "output_raku2.txt";' }
    nok 'output_raku2.txt'.IO.e,
        '2: .raku file: "> filename" with space is comparison, no file written';
    'output_raku2.txt'.IO.unlink if 'output_raku2.txt'.IO.e;
}

# 3. `<file` at the start of a statement is not input redirection in a .raku
#    file either: the spelling does not compile as Raku.
{
    my $threw = False;
    try {
        EVAL '<gating_input.txt say 1;';
        CATCH { default { $threw = True } }
    }
    ok $threw, '3: .raku file does not accept input redirection syntax';
}

# 4. `LVALUE <file` is not a load in a .raku file: the spelling does not
#    compile as Raku (an unterminated word list), so nothing is assigned.
{
    'gating_load.json'.IO.spurt('[1, 2, 3]');
    my $loaded = try EVAL 'my @a <gating_load.json; @a.elems';
    nok $loaded && $loaded == 3, '4: .raku file does not load with <file';
    'gating_load.json'.IO.unlink;
}

done-testing();