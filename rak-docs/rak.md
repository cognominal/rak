# rak

rak is a fork of Rakudo that is both a programming language and a shell, interactive or
not, with features inspired by Nushell and jq. It is Raku with a lighter surface syntax:
fewer brackets and quotes, shell-style words, pipes and redirections, and fast native
variables. Where Perl excelled at matching patterns in strings, rak also aims to match
patterns in data structures.

rak is enabled by the `.rak` file extension, or by running the `./rak` wrapper with no
file (see the [cheat sheet](CHEATSHEET.md#turning-it-on), which also lists the
[environment variables](CHEATSHEET.md#environment-variables)). A `.raku` file keeps
standard Raku semantics. Using rak interactively, in [irak](../rak-plans/features/irak.md), is a good
way to learn it.

rak is developed on the `rak` branch of `https://github.com/cognominal/rakudo`, and on
branches derived from it. This page uses the present tense, but much of what it
describes is planned; [status.md](../rak-plans/status.md) says what exists.

## A taste

```rak
say hello world          # say, with two naked strings
say double 3             # double is a known routine: it is called
my #n = 1;  my ~s = foo  # native int and native str
say %h.users.1.name      # %h<users>[1]<name>
say %h->elems            # a method call
@a >a.json               # write @a as JSON
my %cfg <cfg.json        # load a JSON file
git log | ->unique       # a command piped into a rak method (planned)
```

## rak as the outer layer

Perl was always a guest in someone else's shell. People could write
`dmesg | perl -ne '…'`, but the shell owned the pipe and the redirection, and Perl only
saw stdin. rak takes the opposite position: the language *is* the outer layer. It keeps
the shell's composition (words, pipes, redirections) and the language's power (types,
signatures, data structures), and it uses syntax to settle the conflicts between them:

- [naked strings](../rak-plans/features/naked-strings.md) let words be strings without Perl's
  `strict 'subs'` trap;
- [spacing](../rak-plans/features/spacing.md) tells redirection from comparison;
- the [standard and shell strategies](../rak-plans/features/strategies.md) let a statement be Raku or a
  command line, and pipes mix commands with rak stages;
- [redirection](../rak-plans/features/redirection.md) moves typed values, not only bytes, and
  [URL targets](../rak-plans/features/url-targets.md) extend it to the web;
- [dotty subscripts](../rak-plans/features/dotty-subscripts.md) walk data like jq, and
  [myaml](../rak-plans/features/myaml.md) will pattern-match it.

## Fixing Raku's costs

Raku enables by default several features that are rarely needed yet cost performance:
arbitrary-precision integers, and containers that let any variable be aliased. Every
untyped variable is boxed. Walking data structures takes many brackets. This drove away
people writing small tools, for whom Perl and Raku were too slow to start and too slow at
simple work. rak's [new sigils](../rak-plans/features/sigils.md) `~` and `#` hold native `str` and `int`
values with no boxing, and make bracketless subscripts possible. A third sigil, `^` for
native `num`, is [unsettled](../rak-plans/unsettled.md).

## Less visual noise

Brackets and other paired characters are heavy on the eye. rak removes them where layout
can say the same thing: [indentation](../rak-plans/features/indentation.md) delimits multi-line blocks,
[tree expressions](../rak-plans/features/tree-exprs.md) replace parentheses in multi-line expressions,
and dotty subscripts replace `[…]`, `{…}` and `<…>`.

## Building on Larry Wall's ideas

rak follows Larry Wall in borrowing mechanisms from natural language, in a very different
setting. Where possible, concision wins over regularity: the language is harder to learn,
but no less expressive. Concision comes from [huffing](background/huffing.md): giving
frequent constructs short spellings. Natural languages have registers, spoken and written,
the written one being more formal; rak's shell and standard strategies play the same
roles, and the interactive shell strategy is the spoken one. The full argument is in
[Larry Wall, natural language and pragmatics](background/larry-wall.md).

## Related implementations

Like Rakudo, rak runs on MoarVM, so libraries written in Raku can be used from rak and
the other way round. **Shak**, a simplified rak running on a JavaScript engine, is
anticipated.
