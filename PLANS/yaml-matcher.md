# making rak a native web client to process data

Since Perl has been created in 1987, the programmer work scope  has enlarged.
Instead of
munging local files line by line we need to deal with whole data structures
obtained from the web and sometimes modified and written back to it.
These data structures are written in languages
like yaml or json. Yaml being the superset of these languages.
Rak uses shell redirections. Input redirections pull data from the web and
output redirections write to the
web. Rak uses a modified yaml language called myaml, meaning 'matcher yaml'.
Myaml  extracts data
from data language file.


# `$octacat-data` is a rak data structure
my $octocat-data <  https://api.github.com/users/$user


# myaml

Sigils and parentheses have special meaning in myaml. You must backquote them
if you want to inhibit theses meanings

A double sigil means that the corresponding mono sigil variable is set to the matched
structure. A single sigil means that the value it contains
is added to the structure


```rak
my $data ::=
- name: Jon Doe
  dob:  1952/10/07
```

is short for

my $data := q:to<END>:yaml
- name: Jon Doe
  dob:  1952/10/07
END
```

`q:to<END>` is a raku here in that start at the end of the statement
`my $data := q:to<END>:yaml;
`
The `:yaml` means to interpret the read string as a yaml structure and
a error is emitted at compilation time if the yaml is incorrect.




```rak
my data ::=
- name: Jon Doe
  dob:  1952/10/07
- name: Jane Doe
  dob:  1975/12/24

```

```rak
$matcher :::=
-name: $who
 dob: $$dob
```

$dob = $match


Perl is using regexen to extract data from file lines.
Rak know common file data formats, accesses the web to
read files in such formats and pattern match the
associated data structures.

This is done mostly by new syntactical/semantic extensions
of rak to raku.

- an extension of yaml support pattern matching in data
  structures

redirection from url.

This spec discusses extensions to raku  be implemented in the
future rak. The goal is to pattern match data structure
obtained from local files or from the web with minimum hassles.
No use of libraries or of the executables like curls or jq


It uses interpolation in naked strings.

When redirecting from  urls the yaml file indicates the
http headers to send

Redirection from web url implies useing the right
http headers.




## Redirection to vars

```rak
$struct <file.toml # redirection to var $struct from a file

# redirection to var $octocat-data from an url
# Said url is a naked string with interpolation
my $user = octocat
my $octocat-data <  https://api.github.com/users/$user
```

## matching

```bash
curl -s https://api.github.com/users/octocat/repos | raku -MJSON::Fast -e ' ││ my @repos = from-json($*IN.slurp);                                            ││ my @a = @repos.sort({ -.<stargazers_count> }).map(*.<html_url>);
```


```rak
my $user = octocat
```

## Generating the right http headers

When redirecting from an url an http request is done
and the appropriate headers should be sent.
Most will be pulled from `~/.config/rak/http-headers.yaml`
depending on the host part of the url.

```yaml
api.github.com:
  auth: $GIHUB_TOKEN
 │X-GitHub-Api-Version: 2022-11-28 # Required API versioning header (as of REST API v3 docs)                           │
```

A string prefixed by $ in the YAML file are replaced by environment variable
usually pulled from `~/.secret` by the login shell when it starts.


  auth: $GIHUB_TOKEN

is short for

  authorization: bearer $GITHUB_TOKEN

Note: The file `~/.config/rak/web.yaml` is generated at the
setup of rak for a given user. The setup is implicit.
When no `~/.config/rak/` is present it will be created
with the correct files.





