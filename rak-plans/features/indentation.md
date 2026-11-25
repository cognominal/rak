# Indentation as syntax

In rak, a block that spans several lines is delimited by indentation, not braces. A block
on a single line keeps its braces.

Status: PLANNED 0.4, NEEDSPEC.

```rak
if 1
  say hello world
  say salut
  say one\ string\ hello\ world
```

is the same as

```rak
if 1 {
  say "hello", "world";
  say "salut";
  say "one string hello world";
}
```

This is one point where rak reaches the opposite conclusion from Larry Wall, who kept
braces in Perl.

## Rules

- A block whose body spans several lines must use indentation. Braces around a
  multi-line body are an error.
- A block on one line keeps its braces: `if $x { say yes }`.
- Indentation is measured in spaces. Tabs are not allowed in indentation.
- A newline ends a statement, except inside a [tree expression](tree-exprs.md) or an open
  bracket.

## Implementation

Blocks are parsed today by the `blockoid` token. After a newline, the whitespace rule
must measure the new line's indentation and compare it with the enclosing block's, to
know whether the block continues, a nested block opens, or the block ends.

Grammar rules should not have to spell out indent and dedent tokens. The plan is a
method trait on the rule instead: `is block`, short for `is indent<{ }>`. The trait names
the opening and closing characters used when the block fits on one line; when it does
not, the rule matches an indented block. The same rule then defines both the braced
one-line form and the indented multi-line form.

## Open questions

- How comments and blank lines inside a block affect indentation.
- What error to give for inconsistent indentation, and where to point it.
- Whether a here-document or a multi-line string inside a block is exempt.
