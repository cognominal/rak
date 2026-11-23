# Roadmap

This is a tentative roadmap, not a timeline: it says in which version of
[rak](GLOSSARY.md#rak) each feature is expected to land. It is unrelated to
`docs/ROADMAP`, the upstream Rakudo roadmap, which has not been updated in more than
ten years.

Rak terms link to the rak [glossary](GLOSSARY.md). For Raku terms, see the
[Raku glossary](https://docs.raku.org/language/glossary).

No version has been released yet. I intend to publish 0.1 and later versions on the
[AUR](https://aur.archlinux.org/). Rakudo itself is not in the official
[Arch](https://archlinux.org/) repositories; it is only in the AUR (`rakudo`,
`rakudo-bin`). The current focus is [irak](GLOSSARY.md#irak), the interactive rak.

Backward compatibility will not be preserved before 0.5:
[irak submissions](GLOSSARY.md#irak-submission) are, by nature, throwaway scripts.

A version is either marked as done (none is yet), or its features are split into two
lists: DONE and TBD.

- **0.1**: the first released version.
  - DONE: [naked strings](GLOSSARY.md#naked-string), [jq](https://jqlang.org/manual/)-like subscripting
    ([dotty subscripts](GLOSSARY.md#dotty-subscript)),
    [redirections](GLOSSARY.md#redirection), [URL targets](GLOSSARY.md#url-target)
    (GET and POST, see the [GitHub examples](PLANS/demos/github.md)),
    [bare hosts](GLOSSARY.md#bare-host) (`<api.github.com/…`),
    [commands](GLOSSARY.md#command) and [pipelines](GLOSSARY.md#pipeline) (Unix and
    jq style, mixed; `$?` and `@?`), recalling submissions (`!n`, `!!n`, up and down
    arrows), [topic-keeping submissions](GLOSSARY.md#topic-keeping-submission) (`- `), [paging](GLOSSARY.md#paging) long irak output, the
    [formatter](GLOSSARY.md#formatter) (a lone `.`).
  - TBD:
      - irak usability, discoverability, onboarding feedback thru highlighting. first run of irak or `irak --fresh` should start with a tutorial history (work in branch irak-feedback)
      - aliases
      - [globbing](https://en.wikipedia.org/wiki/Glob_(programming)),
      - the rest
    of HTTP (`http` for PATCH, PUT and DELETE; following pages), a parenthesized command
    as an argument, `cd (zoxide query orbit)`
    ([issue 03](.scratch/commands/issues/03-parenthesized-command-as-argument.md)), and
    trimming the trailing newline of captured output
    ([issue 04](.scratch/commands/issues/04-captured-output-trailing-newline.md)).
- **0.2**: [ZLE](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)-style
  completion, a configurable prompt.
- **0.3**: pattern matching in data structures (live or deserialized) using double sigilled vars. Support of YAML
- **0.4**: indentation as syntax.
- **0.5**: tooling: [LSP](https://microsoft.github.io/language-server-protocol/)
  support, syntax highlighting. irak will also need new interactions to fully fit it as a
  [spoken language](PLANS/background/larry-wall.md#the-command-line-is-a-conversation);
  what they would be is still unknown.
- **0.6** for performance support utf-8 regexen by adapting the eponymous rust package. Default in irak. Raku syntax unchanged.
- **0.7**: a github.io site, and a programming course built with the `/teachme`
  skills that uses irak, rak and agents. It may use [Tauri](https://tauri.app/) and
  [tuios](https://tuios.dev): its
  [control protocol](https://tuios.dev/docs/control-protocol) is the API, and
  [tuios-web](https://tuios.dev/docs/web) serves it in a browser.
