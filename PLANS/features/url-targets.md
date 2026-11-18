# URL targets

Since Perl was created in 1987, the scope of everyday programming has grown. Instead of
munging local files line by line, we fetch whole data structures from the web, sometimes
change them, and write them back. rak handles this with the same
[redirection](redirection.md) syntax as files: a load from a URL is an HTTP GET, and an
output redirection to a URL is a POST. No library, no `curl`, no `jq`.

Status: planned. Every spelling here is tentative. [GitHub](../demos/github.md) is the
planned demonstration.

```rak
my $user = octocat
my %octocat <https://api.github.com/users/$user       # GET, decoded as JSON
say %octocat.public_repos

{ title => 'Test', body => 'from rak' } >https://api.github.com/repos/OWNER/REPO/issues
```

The URL is a [naked string](naked-strings.md) with interpolation. Like any redirection
target, it touches the operator.

## HTTP headers

A request needs the right headers for its host: authentication, API version, accepted
media type. They come from `~/.config/rak/http-headers.yaml`, keyed by host:

```yaml
api.github.com:
  auth: $GITHUB_TOKEN
  X-GitHub-Api-Version: 2022-11-28
```

A value that starts with `$` is replaced by that environment variable, usually set from
`~/.secret` by the login shell. `auth: $GITHUB_TOKEN` is short for
`Authorization: Bearer $GITHUB_TOKEN`. When `~/.config/rak/` is missing, rak creates it
with default files on first use.

## Design questions

- **Format of a URL target.** A file target gets its [format](../../GLOSSARY.md#format)
  from its extension, but API URLs have none. A URL target should get its format from
  the response's `Content-Type` (`application/json`) when loading, and send JSON when
  writing a value. An explicit override may still be needed.
- **Which HTTP method.** A load (`<url`) is a GET, and `>url` with a value is a POST.
  Nothing yet spells PATCH, PUT, or DELETE. `>>url` must not be guessed: for files, `>>`
  to `.json` is an error (ADR 0004).
- **The response to a POST.** The created object, which holds the new resource's number
  and URL, is the useful result. It could become the statement's value, or the
  [irak topic](../../GLOSSARY.md#irak-topic) in irak.
- **Secrets.** The token must never be written in a script. A `gh auth token` fallback
  for `api.github.com` would save configuring it.
- **Pagination.** Following the `Link` header could make a list endpoint a lazy `Seq` of
  all pages. It must stay lazy, or a single statement can use up a rate limit.
- **Lexing.** A URL contains `:`, `/`, `?`, `&` and `{…}`. Which of these end the target,
  and where an interpolated `$user` ends, has to be decided with the naked-string rules.
- **Errors.** A `4xx` or `5xx` response should fail the statement with the server's
  message, not load the error body as data.
- **Tests.** Tests must not hit the network. They need a local HTTP fixture that serves
  canned responses.
