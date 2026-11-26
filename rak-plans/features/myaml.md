# myaml: matching data structures

Perl extracts data from lines of text with regexes. rak aims to do the same for data
structures: read a file or a [URL](url-targets.md) in a data format, then pattern-match
the structure. The pattern language is **myaml** ("matcher YAML"), an extension of YAML,
which is itself a superset of JSON.

Status: PLANNED 0.3, NEEDSPEC — the matching semantics below are a sketch.

## YAML literals

`::=` binds a variable to a YAML literal written after it:

```rak
my $data ::=
- name: Jon Doe
  dob:  1952/10/07
- name: Jane Doe
  dob:  1975/12/24
```

is short for

```rak
my $data := q:to<END>:yaml;
- name: Jon Doe
  dob:  1952/10/07
- name: Jane Doe
  dob:  1975/12/24
END
```

`q:to<END>` is Raku's here-document, which starts after the end of the statement.
`:yaml` parses the string as YAML, and malformed YAML is a compile-time error. The
parser is rak's [YAML](yaml.md) loader, so its tags and schema apply: under YAML 1.2,
`dob: 1952/10/07` is a string, and `dob: !!timestamp 1952-10-07` a date.

myaml itself is a special mode of that loader, to be specified: only in it do `$x` and
`$$x` have a meaning.

## Patterns

`:::=` binds a matcher written in myaml:

```rak
my $matcher :::=
- name: $who
  dob: $$dob
```

In myaml, sigils and parentheses have a meaning. Backslash them to use them literally.

- A **single sigil** (`$who`) interpolates: the variable's current value must be found at
  that place in the structure.
- A **double sigil** (`$$dob`) captures: on a match, `$dob` is set to the matched value.

## Example

Find a user's repositories sorted by stars. Today:

```sh
curl -s https://api.github.com/users/octocat/repos |
  raku -MJSON::Fast -e 'my @repos = from-json($*IN.slurp);
    say @repos.sort({ -.<stargazers_count> }).map(*.<html_url>)'
```

In rak, the load replaces `curl` and `from-json`, and a myaml pattern would replace the
subscripting.

## Open questions

- How a match reports several results (one per list element, or the first only).
- What `$$dob` holds when the pattern matches inside a list: one value, or all of them.
- Whether `::=` and `:::=` should be two operators, or one with the pattern detected by
  its `$$` captures.
