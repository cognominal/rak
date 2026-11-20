# Output redirection to a URL target gives the response as the statement's value

`STMT >https://…` sends the statement's output as the body of a POST, following ADR 0002
and ADR 0004: the printed text if the statement printed, its value otherwise, always as
JSON. Unlike a file target, whose statement keeps its own value, the statement's value
becomes the server's response, decoded by its media type. A POST creates something, and
the created object (its number, its URL) is the only result worth keeping. In irak it
becomes the topic, so `.html_url` comes next.

## Considered Options

- **Keep the statement's own value, as for a file.** Rejected: the value is what was just
  sent, which the user already has. The response would need a second spelling.
- **Store the response in a separate variable (like `$?` for commands).** Rejected for
  now: it adds a name to learn for the common case.

## Consequences

- `%issue >https://…/issues` and `%issue >issue.json` have different values. Code that
  uses the value of a redirected statement must know which kind of target it has.
- A response with no body (`204 No Content`) gives `Nil`.
- An error response (4xx, 5xx) throws `X::Rak::HTTP` instead of becoming the value.
- `>>` to a URL target is an error: appending has no HTTP meaning.
