# URL targets

Since Perl was created in 1987, the scope of everyday programming has grown. Instead of
munging local files line by line, we fetch whole data structures from the web, sometimes
change them, and write them back. rak handles this with the same
[redirection](redirection.md) syntax as files: a load from a URL is an HTTP GET, and an
output redirection to a URL is a POST. No library, no `curl`, no `jq`.

Status: GET (load) and POST (output redirection) are implemented; see
[status](../status.md). Usage is in the [cheat sheet](../docs/CHEATSHEET.md#url-targets-http-https).
[GitHub](../demos/github.md) is the planned demonstration.

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
media type. They come from `~/.config/rak/http-headers.json` (under `$XDG_CONFIG_HOME`
when it is set), keyed by host, or by `host:port` first. It is read with the relaxed JSON
decoder, so comments and unquoted keys are allowed:

```json
{
  'api.github.com': { auth: '$GITHUB_TOKEN', 'X-GitHub-Api-Version': '2022-11-28' },
}
```

A value that starts with `$` is replaced by that environment variable, usually set from
`~/.secret` by the login shell; when the variable is unset, the header is left out.
`auth: $GITHUB_TOKEN` is short for `Authorization: Bearer $GITHUB_TOKEN`. With no
authorization configured, `api.github.com` uses the token of `gh auth token`. rak does
not create `~/.config/rak/`. The file will move to YAML once rak reads YAML.

## Decisions

- **Transport.** Every request goes through one internal routine,
  `Rakudo::Internals::RakHTTP.request`. It runs `curl`, which reads its options (the URL
  and the headers, so the token) on standard input, never in its argument list. Without
  `curl` on `$PATH`, it uses `HTTP::UserAgent`, which Rakudo Star bundles, through
  `$*REPO.need`. Rakudo's core has no TLS, and requiring Star would cost a recompile of
  its modules after every rakudo rebuild.
- **Forms.** `LVALUE <url` and `<url` are a GET; `STMT >url` is a POST, also for a
  command's output. `>>url`, `<url STMT` and `2>url` are compile-time errors (a run-time
  error when the target is a variable). `<url STMT` may come later.
- **Lexing.** A naked URL target starts with `http://` or `https://` and takes the
  characters `[\w-.~:/?&=+%@!,*']`; whitespace, `;`, `#`, `{`, `}`, `(` and `)` end it. It
  interpolates `$name` only, the name ending as a Raku identifier does (`$user-x` is the
  variable `$user-x`). `{` is excluded because API docs write `{owner}` for a
  placeholder. A double-quoted target interpolates everything.
- **Bare hosts.** A naked load target may drop `https://`:
  `<api.github.com/users/$user` is `<https://api.github.com/users/$user`. The part before
  the first `/` is a host when its last label is a top-level domain (ignoring case) and
  it has three labels or more, or is followed by `/`. So `api.github.com` and
  `github.com/rakudo` are URLs, while `README.md` and `example.com` alone are files.
  - Only loads take a bare host: `LVALUE <host…`, `<host…` and a pipeline's leading
    load. `>api.github.com` writes a file; `2>`, `>>` and a command's `<` too.
  - Only naked targets: `<'api.github.com'`, `<"…"` and `<$t` are files.
  - The scheme is always `https://`.
  - It is decided at compile time from the spelling. When a file of that name exists
    then, the compiler warns: ``<api.github.com` loads https://api.github.com; write
    `<./api.github.com` for the file``. `./` and `../` start a naked file path.
  - The top-level domains are a snapshot of IANA's root zone
    (`https://data.iana.org/TLD/tlds-alpha-by-domain.txt`) in `src/Rak/Grammar.nqp`;
    `raku tools/update-tlds.raku` refreshes it. Many collide with extensions (`.md`,
    `.pl`, `.py`, `.sh`, `.zip`), which is why two labels alone are not enough.
- **Format.** A response whose media type is `application/json` or ends in `+json` is
  decoded as JSON; any other is text, and loads as text does from a file. A POST body is
  always JSON: the value, or the printed text, which must decode as JSON (ADR 0004).
- **The response to a POST** is the statement's value, decoded, and `Nil` when empty
  ([ADR 0005](../../docs/adr/0005-a-url-target-gives-the-response-as-the-statement-value.md)).
- **Errors.** A 4xx or 5xx response throws `X::Rak::HTTP` with `status`, `url` and
  `reason` (the JSON body's `message`, or its first line). A failed connection throws it
  with no status.
- **Tests.** `t/14-redirection/rak/013-url-load.rak` and `014-url-post.rak` run against
  `t/packages/RakHTTPFixture`, a local HTTP/1.1 server that serves canned responses and
  records the requests. Bare hosts are in `015-bare-host.rak`, which points curl at an
  unreachable proxy and checks the URL in the error.

## Open questions

- **Which HTTP method.** Nothing yet spells PATCH, PUT, or DELETE.
- **Format override.** A way to force a format when the media type is wrong.
- **Pagination.** Following the `Link` header could make a list endpoint a lazy `Seq` of
  all pages. It must stay lazy, or a single statement can use up a rate limit.
- **Input redirection** from a URL, `<url STMT`.
