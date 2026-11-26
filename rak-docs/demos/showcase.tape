# showcase.tape — a tour of irak, rendered to showcase.gif by vhs.
# Rebuild from the repo root with `make rak-demos`, or `vhs rak-docs/demos/showcase.tape`.
# Local data only, so a rebuild gives the same GIF.
#
# Each submission is typed with its comment at column 41 (two spaces after the
# code when the code is longer), then ENTER, a short pause (irak redraws the line
# colored, with any `my` it adds), and a second ENTER within irak's one-second
# window to run it. Each step then waits for irak's next prompt rather than
# guessing a delay, so a slow network or a slow fzf only lengthens the pause.

Output rak-docs/demos/showcase.gif

Set Shell "bash"
Set FontSize 18
Set Width 1300
Set Height 840
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

Hide
Type "clear; rak-docs/demos/run-demo"
Enter
Wait+Screen@60s /\[0\] >/
Show
Sleep 1.5s

Type "say [hello world]"
Type@15ms "                       # naked strings: no quotes"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "%h = {a => 1, b => [5, 6]}"
Type@15ms "              # ENTER once: irak adds my"
Enter
Sleep 700ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "%h.b.1"
Type@15ms "                                  # dotty subscript: %h<b>[1]"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "->succ"
Type@15ms "                                  # method call on the topic $_"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "my %d <data.json"
Type@15ms "                        # load: .json picks the format"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2.5s
Type "%d."
Sleep 500ms
Tab
Wait+Screen@15s /Hash ·/
Sleep 1.5s
Type@200ms "dep"
Sleep 1.5s
Enter
Wait@15s /%d\.deps *$/
Sleep 500ms
Type@15ms "                                 # TAB: fzf picks a key, previews it"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "%d.deps >deps.json"
Type@15ms "                      # write: .json picks the format"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "cat deps.json"
Type@15ms "                           # an external command, as in a shell"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2.5s
Type "%d"
Type@15ms "                                      # $_ is now the hash"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "-"
Type@15ms "                                       # pin the topic: the prompt ends in -"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type ".deps.fzf"
Type@15ms "                               # pinned: look around, $_ stays"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "! .name"
Type@15ms "                                 # `! ` sets $_ even while pinned"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 2s
Type "-"
Type@15ms "                                       # unpin"
Enter
Sleep 600ms
Enter
Wait@30s /\] >-? *$/
Sleep 3.5s
