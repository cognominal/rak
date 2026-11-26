# web.tape — pipes and the web in irak, rendered to web.gif by vhs.
# Rebuild from the repo root with `make rak-demos`, or `vhs rak-docs/demos/web.tape`.
# Needs the network: the star count and rate limit change from one rebuild to the next.
#
# Each submission is typed with its comment at column 41 (two spaces after the
# code when the code is longer), then ENTER, a short pause (irak redraws the line
# colored, with any `my` it adds), and a second ENTER within irak's one-second
# window to run it. Each step then waits for irak's next prompt rather than
# guessing a delay, so a slow network or a slow fzf only lengthens the pause.

Output rak-docs/demos/web.gif

Set Shell "bash"
Set FontSize 18
Set Width 1300
Set Height 420
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

Hide
Type "clear; rak-docs/demos/run-demo"
Enter
Wait+Screen@60s /\[0\] >/
Show
Sleep 1.5s

Type "<data.json | .frontends | ^sort -r"
Type@15ms "      # pipe: rak stages into a command"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "<api.github.com/repos/rakudo/rakudo | .stargazers_count"
Type@15ms "  # GitHub: a URL load"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 4s
Type "@*IWEB[*-1]<method status url>"
Type@15ms "          # irak's web log: the request"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2.5s
Type "@*IWEB[*-1].out<content-type x-ratelimit-remaining>"
Type@15ms "  # its response headers"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 4s
