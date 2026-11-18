# Larry Wall, natural language and pragmatics

Larry Wall studied linguistics before he wrote Perl. He and his wife
Gloria were graduate students in linguistics at UC Berkeley, preparing
to become missionary linguists: to live with a people whose language
had no written form, write it down, and help translate the Bible. The
plan was abandoned, and Wall went to work at NASA's Jet Propulsion
Laboratory instead
([Wikipedia](https://en.wikipedia.org/wiki/Larry_Wall)). He calls
himself "a 50/50 hybrid" of linguist and computer scientist
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).

In *Natural Language Principles in Perl*
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)),
he argues that a computer language should borrow from how people really
speak. Some of its principles, in his words:

- **Learn it once, use it many times**: "You learn a natural language
  once and use it many times."
- **Learn as you go**: "It's okay if a language is difficult to learn,
  as long as you don't have to learn it all at once."
- **Multiple ways to say the same thing**: "Just because Perl is the
  melting pot of computer languages doesn't mean you have to stir."
- **Local ambiguity is okay**: "People thrive on ambiguity, as long as
  it is quickly resolved."
- **Topicalization**: "A topicalizer simply introduces the subject
  you're intending to talk about."
- **Pronominalization**: "`$_` means "it", and `@_` tends to mean
  "them"."

Elsewhere he sums it up: "Natural languages are not orthogonal, they're
diagonal"
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).
And the preface of *Programming Perl* states the goal: "Perl is designed
to make the easy jobs easy, without making the hard jobs impossible"
([O'Reilly](https://www.oreilly.com/library/view/programming-perl-3rd/0596000278/pr02.html)).

## Pragmatics

Linguists split meaning into layers. **Syntax** is how words combine.
**Semantics** is what the combination means on its own. **Pragmatics**
is what it means *in context*: who is speaking, to whom, when and why.
"Can you pass the salt?" is a question about ability by its semantics,
and a request by its pragmatics. Pragmatics studies:

- **[deixis](https://en.wikipedia.org/wiki/Deixis)**: words that point to the situation, such as *I*, *here*,
  *now* and *that*;
- **implicature**: what is meant without being said (Grice's
  [cooperative principle](https://en.wikipedia.org/wiki/Cooperative_principle): say as much as needed, no more, and stay
  relevant);
- **ellipsis**: leaving out what the context already provides.

Wall doesn't use the word, but context is at the center of his
thinking. The school of linguistics he trained in, tagmemics (developed
by Kenneth L. Pike), "makes a big deal about context", and of human
listeners he says: "If there's a way to make sense of something in a
particular context, they'll do so"
([Dr. Dobb's, 1998](https://jacobfilipp.com/DrDobbs/articles/DDJ/1998/9802/9802a/9802a.htm)).
`$_`, default arguments and context-sensitive operators are pragmatics
turned into language features: a program is said *in* a context, and a
good language lets that context do part of the work.

## Spoken first

Natural languages are spoken before they are written. Speech is far
older than writing, and most of the world's languages have never been
written down. Academies like the Académie française, founded by
Richelieu in 1635
([Wikipedia](https://en.wikipedia.org/wiki/Acad%C3%A9mie_fran%C3%A7aise)),
have tried to legislate the written language for centuries, but usage
wins: speakers shorten, borrow and reshape words, and dictionaries
follow, sometimes generations later. Writing is the formal register;
speech is where the language lives and changes. Wall notes what writing
loses: "Natural language is naturally punctuated by the pitches,
stresses and pauses we use to indicate how words are related"
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)).
rak's spacing rules are a form of that prosody: `$a > $b` and `say x >out`
differ only in where the pauses fall.

## The command line is a conversation

A program file is the written register: composed, revised, read by
others later. The command line is the spoken register:

- **turn-taking**: the prompt hands the floor to you, the output answers;
- **shared context**: the current directory, the history, the previous
  result;
- **deixis and ellipsis**: `cd -`, `!!` and `$_` point to what was just
  said instead of repeating it;
- **repair**: you recall a line, fix it and say it again;
- **short turns**: nobody declares variables in a conversation.

So the command line fits Wall's thesis even better than a program file
does. That is the missed opportunity. Perl applied natural-language
principles to the written register, while the spoken register, the
shell, stayed with `sh` and its descendants. Wall himself pointed at
the shells' grammar: unlike Perl, they "make use-vs-mention distinctions
using a `$` prefix"
([original](http://www.wall.org/~larry/natural.html),
[copy](https://gist.github.com/uzluisf/9ef7a3ede109b32e15085a6beccfa7c4)).
rak's naked strings take that distinction back: a naked string mentions
a word, and a sigil uses a variable. Raku went further toward the formal
register. rak takes up the opportunity: the standard strategy is the
written register, the shell strategy is the spoken one, and irak is the
conversation, where the irak topic `$_` is the "it" of the previous irak
submission.

