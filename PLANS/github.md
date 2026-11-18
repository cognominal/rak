# GitHub as a rak demonstration

The GitHub REST API makes a good showcase for rak. Every request and response is
JSON, the URLs are readable, and the everyday tasks are short one-liners: read a
repo, list commits, open an issue, comment on a PR. In a shell these take
`curl … | jq …`. In plain Raku they take an HTTP module, `from-json`, and hash
subscripts. rak should do them with a [load](../GLOSSARY.md#load) and dotty
subscripts for GET, and with [value-mode](../GLOSSARY.md#value-mode) output
redirection for POST.

This depends on URL redirection targets, which `PLANS/shell.md` lists as planned and
`PLANS/rak.md` mentions under "http requests GET and POST". Every rak spelling below
is tentative.

## Reference documentation

- [REST API overview](https://docs.github.com/en/rest)
- [Getting started](https://docs.github.com/en/rest/using-the-rest-api/getting-started-with-the-rest-api):
  base URL `https://api.github.com`, headers, JSON bodies, status codes
- [Authentication](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api):
  `Authorization: Bearer <token>`
- [Rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api):
  60 requests/hour unauthenticated, 5000 with a token
- [Pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api):
  `per_page`, `page`, and the `Link` response header
- [Media types](https://docs.github.com/en/rest/using-the-rest-api/media-types):
  `Accept: application/vnd.github+json`
- [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions):
  the `X-GitHub-Api-Version` header
- [GraphQL API](https://docs.github.com/en/graphql): one endpoint, `POST /graphql`
- [`gh api`](https://cli.github.com/manual/gh_api): the GitHub CLI's raw API client,
  a good baseline to compare rak against

## GET endpoints

These need no token for public data, which makes them good for demos and tests.

| Endpoint | Returns | Docs |
|---|---|---|
| `/repos/{owner}/{repo}` | repo metadata (nested object) | [repos](https://docs.github.com/en/rest/repos/repos) |
| `/repos/{owner}/{repo}/languages` | bytes per language (flat hash) | [repos](https://docs.github.com/en/rest/repos/repos) |
| `/repos/{owner}/{repo}/commits` | commits (array, paginated) | [commits](https://docs.github.com/en/rest/commits/commits) |
| `/repos/{owner}/{repo}/issues` | issues and PRs (array) | [issues](https://docs.github.com/en/rest/issues/issues) |
| `/repos/{owner}/{repo}/pulls` | pull requests | [pulls](https://docs.github.com/en/rest/pulls/pulls) |
| `/repos/{owner}/{repo}/releases` | releases | [releases](https://docs.github.com/en/rest/releases/releases) |
| `/repos/{owner}/{repo}/contents/{path}` | a file (base64 `content`) or a directory listing | [contents](https://docs.github.com/en/rest/repos/contents) |
| `/repos/{owner}/{repo}/git/trees/{sha}?recursive=1` | the whole tree | [trees](https://docs.github.com/en/rest/git/trees) |
| `/search/repositories?q=…` | search results (`items` array) | [search](https://docs.github.com/en/rest/search/search) |
| `/users/{user}/gists` | gists | [gists](https://docs.github.com/en/rest/gists/gists) |
| `/emojis` | name → image URL (large flat hash) | [emojis](https://docs.github.com/en/rest/emojis/emojis) |
| `/rate_limit` | remaining quota | [rate limit](https://docs.github.com/en/rest/rate-limit/rate-limit) |

## POST endpoints

All of these need a token. The body is a JSON object, and a create returns `201`
with the new object.

| Endpoint | Body | Docs |
|---|---|---|
| `/repos/{o}/{r}/issues` | `title`, `body`, `labels`, `assignees` | [issues](https://docs.github.com/en/rest/issues/issues) |
| `/repos/{o}/{r}/issues/{n}/comments` | `body` | [comments](https://docs.github.com/en/rest/issues/comments) |
| `/repos/{o}/{r}/labels` | `name`, `color`, `description` | [labels](https://docs.github.com/en/rest/issues/labels) |
| `/repos/{o}/{r}/pulls` | `title`, `head`, `base`, `body`, `draft` | [pulls](https://docs.github.com/en/rest/pulls/pulls) |
| `/repos/{o}/{r}/pulls/{n}/reviews` | `event`, `body`, `comments` | [reviews](https://docs.github.com/en/rest/pulls/reviews) |
| `/repos/{o}/{r}/releases` | `tag_name`, `name`, `body`, `draft` | [releases](https://docs.github.com/en/rest/releases/releases) |
| `/repos/{o}/{r}/statuses/{sha}` | `state`, `context`, `target_url` | [statuses](https://docs.github.com/en/rest/commits/statuses) |
| `/repos/{o}/{r}/actions/workflows/{id}/dispatches` | `ref`, `inputs` (returns `204`) | [workflows](https://docs.github.com/en/rest/actions/workflows) |
| `/gists` | `files`, `public`, `description` | [gists](https://docs.github.com/en/rest/gists/gists) |
| `/markdown` | `text`, `mode`, `context` (returns HTML) | [markdown](https://docs.github.com/en/rest/markdown/markdown) |
| `/graphql` | `query`, `variables` | [GraphQL](https://docs.github.com/en/graphql) |

Updates use `PATCH`, for example closing an issue with `{state: closed}`, and
deletes use `DELETE`.

## Side by side (tentative rak)

Reading a repo's star count:

```sh
curl -s https://api.github.com/repos/rakudo/rakudo | jq .stargazers_count
```

```raku
use HTTP::Tiny; use JSON::Fast;
say from-json(HTTP::Tiny.get('https://api.github.com/repos/rakudo/rakudo')<content>.decode)<stargazers_count>;
```

```rak
my %repo <https://api.github.com/repos/rakudo/rakudo
say %repo.stargazers_count
```

Listing the authors of the last commits:

```rak
<https://api.github.com/repos/rakudo/rakudo/commits
say .map(*.commit.author.name).unique
```

Opening an issue. This is value mode: the statement prints nothing, so its value is
encoded as JSON and sent:

```rak
{ title => 'Test', body => 'from rak' } >https://api.github.com/repos/OWNER/REPO/issues
```

Saving an API response to a file, with the format coming from the file's extension:

```rak
<https://api.github.com/repos/rakudo/rakudo/languages >langs.json
```

## Design questions

- **Format of a URL target.** A file target gets its [format](../GLOSSARY.md#format)
  from its extension, but API URLs have none. A URL target should get its format from
  the response's `Content-Type` (`application/json`) when loading, and send JSON when
  writing a value. An explicit override may still be needed.
- **Which HTTP method.** A load (`<url`) is a GET, and `>url` with a value is a POST.
  Nothing yet spells PATCH, PUT, or DELETE. `>>url` must not be guessed: for files,
  `>>` to `.json` is an error (ADR 0004).
- **The response to a POST.** The created object, which holds the issue number and
  URL, is the useful result. It could become the statement's value, or the
  [irak topic](../GLOSSARY.md#irak-topic) in irak.
- **Headers and authentication.** The token has to come from somewhere implicit
  (`GITHUB_TOKEN`, or `gh auth token`) scoped to `api.github.com`, never written in the
  script. The same goes for `Accept` and `X-GitHub-Api-Version`.
- **Pagination.** Following the `Link` header could make a list endpoint a lazy `Seq`
  of all pages. It must stay lazy, or a single statement can use up the 60/hour
  unauthenticated quota.
- **Lexing.** A URL written as a naked string contains `:`, `/`, `?`, `&`, and `{…}`.
  Which of these end the target, and whether `{owner}` interpolates, has to be
  decided together with the [naked string](naked-strings.md) rules.
- **Errors.** A `4xx` or `5xx` response should fail the statement with GitHub's JSON
  `message` field, not load the error body as data.
- **Tests.** Tests must not hit the network. They need a local HTTP fixture that serves
  canned GitHub responses, and only the demo should talk to `api.github.com`.
