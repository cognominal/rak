# Huffing: rak and the Huffman principle

In 1952 David A. Huffman found the optimal way to encode symbols: give
the most frequent symbols the shortest codes. Wall made it a design
rule for Perl 6: "Common operations should be "Huffman coded." That is,
frequently used operators should be shorter than infrequently used
ones"
([Apocalypse 3, 2001](https://web.do.metacpan.org/pod/share::Apocalypse::A03)).
He applies it to his own language: "For how often it's used, the
`scalar` operator of Perl 5 is too long, in my estimation."

We use the shorter verb **to [huff](../../GLOSSARY.md#huff)**: to give a construct a spelling
whose length fits its frequency. Common constructs are huffed short;
rare ones may be *[unhuffed](../../GLOSSARY.md#unhuff)*, made longer and more explicit, to free a
short spelling for something more common. (In everyday English, to huff
is to puff or to sulk. Here it is jargon. Shortening "Huffman code" to
"huff" is itself a huff.)

## Natural language huffs itself

Huffing isn't an invention of programmers. Zipf's law of abbreviation
([Wikipedia](https://en.wikipedia.org/wiki/Brevity_law)), from his 1935
book *The Psycho-Biology of Language*, says that frequent words tend to
be short, and speakers keep shortening the ones that become frequent:

- *omnibus* → *bus*, *laboratory* → *lab*, *television* → *TV*;
- *métropolitain* → *métro*, *réfrigérateur* → *frigo*,
  *cinématographe* → *cinéma* → *ciné*;
- pronouns huff whole noun phrases: "the file we just loaded" → "it".

None of these were decreed by an academy. Speakers huffed them, and the
written language followed. That is the sense in which rak huffs Raku:
it shortens what the conversation uses most.

## What rak huffs

| Raku | rak | What gets cheaper |
|---|---|---|
| `say 'foo'` | `say foo` | naked strings: no quotes |
| `f 'a', 'b'` | `f a b` | arguments placed side by side: no commas |
| `%h<name>`, `@a[1]` | `%h.name`, `@a.1` | dotty subscripts |
| `$_<name>` | `.name` | the topic, implicit |
| `$obj.meth` | `$obj->meth` | parameterless method call |
| `my str $s`, `my int $n` | `my ~s`, `my #n` | the new sigils |
| `spurt 'f.json', to-json @a` | `@a >f.json` | output redirection with a format |
| `my %h = from-json slurp 'f.json'` | `my %h <f.json` | load |

Planned huffs include one-letter variables without sigils, indentation
in place of braces, and pipes in the shell strategy.

## What huffing costs

Short spellings are a limited resource: each one is taken from
something else. Wall calls this the waterbed theory: "The waterbed
theory of linguistic complexity says that if you push down one place,
it goes up somewhere else"
([Apocalypse 5, 2002](https://www.perl.com/pub/2002/06/04/apo5.html/),
[copy](https://web.do.metacpan.org/pod/share::Apocalypse::A05)).
In rak, `.5` is `$_[5]`, not a number; `#n` is a
variable, so comments need a space after `#`; `~foo` is a variable, not
"stringify `foo()`"; and `.meth` without parentheses is a subscript.
Each of these unhuffs a rare Raku construct to huff a frequent rak one.
That trade is worth it only when frequency justifies it, and frequency
on the command line is not the same as in a module. This is why the
huffs are limited to rak mode: `.raku` files keep Raku's spellings.

