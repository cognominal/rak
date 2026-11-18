# Terminals, from Teletypes to Herdr

The [history of shells](shells.md) is about the **shell** — the command interpreter. But a
shell has to run *inside* something that draws characters and reads
keystrokes: the **terminal**. That's a separate lineage, and it's worth
tracing on its own, because Herdr — which you use daily — is its current
endpoint.

**Teletypes (1930s–1970s).** The literal, physical ancestor: a
teleprinter — the Teletype **ASR-33** is the canonical Unix-era example —
with a keyboard and a printer, no screen. "Terminal" meant an actual piece
of hardware bolted to a serial line. Unix conventions still carry its
fingerprints: `stty`, `tty`, and the very word "terminal" itself.

**Glass ttys and VT100 (1970s).** DEC's **VT52** (1975) and especially the
**VT100** (1978) replaced the paper with a screen but kept emulating a
serial terminal's behavior — including a specific set of cursor-control
**escape sequences**. The VT100's sequences became the de facto standard:
every terminal emulator discussed below, including Herdr, still describes
its baseline compatibility as "VT100-ish" or "xterm-ish," fifty years on.

**xterm (1984).** Written at MIT's Project Athena (Mark Vandevoorde, later
Thomas Dickey as long-time maintainer), xterm moved terminal emulation
into software, as a window on a Unix workstation running X11. It's the
reason a "terminal emulator" is a program at all rather than a serial
cable — and its escape-sequence dialect (`xterm-256color`, mouse
reporting, etc.) is the other baseline every later emulator targets.

**GNU Screen (1987).** The first mainstream **terminal multiplexer**:
run several windows inside one terminal session, and — critically —
**detach** from it and reattach later, from a different terminal
entirely. This is what made a remote Unix session survive a dropped SSH
connection, decades before "your agent kept working while your laptop
slept" was a design goal.

**tmux (2007).** **Nicholas Marriott** rewrote screen's idea with a
cleaner client-server architecture and saner configuration/scripting,
and tmux displaced screen as the standard multiplexer for the next
fifteen-plus years — panes, windows, sessions, a prefix key, all backed
by a persistent server process a client attaches to.

**GPU-rendered emulators (2016–2024).** A wave of emulators rewrote the
*rendering* side for speed and modern features, largely leaving the
multiplexing job to tmux: **Alacritty** (2016, Rust, minimalist and
GPU-accelerated), **kitty** (2017, Kovid Goyal, GPU-accelerated with its
own tabs/splits and an inline image protocol), **WezTerm** (2020, Wez
Furlong, Rust, with multiplexing built in, including over SSH), and
**Ghostty** (2024, Mitchell Hashimoto, Zig, native platform integration).
This is also the generation Omarchy's default terminals (Alacritty,
foot, kitty, Ghostty) come from.

**Herdr (2026).** Where tmux multiplexes panes for *you* to type into,
Herdr — from **herdrdev** (`herdr.dev`), written in Rust — multiplexes
panes that **AI coding agents** (Claude Code, Codex, Cursor, opencode,
and others) run in, plus your own shells alongside them. It keeps
tmux's model — a persistent server, workspaces/tabs/panes, a prefix key
— but adds what plain multiplexing never needed before: every pane
carries **agent state** (working, blocked, idle) that Herdr surfaces
directly, sessions ride out a disconnect, closed lid, or full reboot the
way tmux/screen sessions always have, and both keyboard-prefix and mouse
interaction are first-class rather than mouse being an afterthought. It's
the same detach/reattach idea GNU Screen introduced in 1987, extended
from "processes you started" to "agents that are still working when you
look away."

**tuios (2026).** A terminal window manager with a daemon, written in
Go, that manages sessions (named workspaces), each holding one pane per
window, grouped into numbered workspaces. A persistent daemon owns the
workspaces over a Unix socket, so sessions survive disconnection and
reboot the way tmux and screen always have. tuios goes beyond plain
multiplexing with an agent-native design: panes carry grants (read,
write, fan, respond, admin) for fine-grained access control, a query
socket lets in-pane processes inspect and control other panes by UUID,
and a tmux shim lets tmux-only tools drive tuios panes transparently.
Agents in tuios panes can announce their own state (working, blocked,
idle) that tuios surfaces in its UI alongside the person's view,
making it as much a multi-agent control surface as a terminal
multiplexer.

**charmbracelet (2022–2026).** A GitHub organization
(`github.com/charmbracelet`) that produces a stack of Go libraries and
tools purpose-built for terminal UIs. The core libraries are:

* **ultraviolet** — terminal I/O: keyboard and mouse events, screen
  buffers, styles, hyperlinks, clipboard, and color profiles.
* **bubbletea** — a TUI protocol and rendering framework: screen
  writing, terminal-size detection, cursor management.
* **bubbles** — reusable UI widgets: cursor, file picker, paginator,
  spinner, table, text area, text input, key binding help.
* **lipgloss** — border drawing and text wrapping.
* **glamour** — syntax highlighting.
* **harmonica** — spring-animation helpers.

These libraries are the building blocks behind several prominent
terminal applications. **tuios** uses ultraviolet, bubbletea, lipgloss,
and the bubbles cursor. **superfile** (`spf`, a terminal file manager)
uses ultraviolet, bubbletea, and the charmap encoding library. **gum**
(a shell-script TUI component tool) uses ultraviolet and bubbles.
**vhs** (a terminal GIF/cast recorder, also from charmbracelet) rounds
out the ecosystem.

## Accessing charmbracelet from Perl and Raku

Since the charmbracelet libraries are written in Go, calling them
directly requires bridging the language boundary.  Both Raku and Perl
have foreign-function-interface (FFI) facilities, and both can also
reach the libraries indirectly through the command-line tools they
power.

| Approach | Works today? | Effort |
|----------|-------------|--------|
| **Raku `NativeCall`** — built-in FFI. Load a `.so` and
declare function signatures. No extra modules needed. | Needs
`lib*.so` compiled from Go first | Medium |
| **Perl `FFI::Platypus`** — de‑facto FFI for Perl 5.
Attach C functions dynamically. | Needs CPAN install + `lib*.so` |
Medium |
| **`gum` sub‑process** — `gum` (already installed,
`/usr/bin/gum`) wraps ultraviolet + bubbles behind a clean CLI.
Call it with `run()` / backticks from any language. | **Works right
now** | Low |
| **tuios socket API** — the daemon at
`/run/user/*/tuios/tuios.sock` accepts JSON commands and emits
JSON-line events. Any language with a socket library can connect. |
**Works right now** | Low |
| **Go shim co‑process** — write a small Go binary that imports
the charmbracelet libraries and communicates over stdin/stdout as
JSON or line protocol. | **Works right now** (compile once) |
Low–medium |

**Raku** (`NativeCall`) works out of the box — no CPAN/Zef install
needed.  **Perl** needs `cpan install FFI::Platypus` (or the older
`Inline::C` / XS routes).  Neither has pre‑compiled charmbracelet
`.so` files available on this system yet, so the two practical paths
today are:

1.  **`gum` sub‑process** — trivially call `gum input`, `gum choose`,
    `gum style`, etc. from either language.
2.  **Write a thin Go shim** — a twenty‑line Go program that links
    the charmbracelet libraries and speaks JSON on stdio.

Once a `.so` is produced (`go build -o libultraviolet.so` with
exported C‑compatible wrappers), both languages can load it and call
the full charmbracelet API directly.

## Terminal timeline at a glance

| Year | Terminal / multiplexer | Key contribution |
|------|-------------------------|-------------------|
| 1930s–70s | Teletype (e.g. ASR-33) | Physical terminal: keyboard + printer, no screen |
| 1975 | VT52 (DEC) | First widely-used screen-based ("glass tty") terminal |
| 1978 | VT100 (DEC) | Escape-sequence dialect that became the de facto baseline |
| 1984 | xterm | Terminal emulation moves into software, on X11. Resizable, client informed thru SINGWINCH signal |
| 1987 | GNU Screen | Detachable multiplexing — sessions survive disconnection |
| 2007 | tmux | Client-server multiplexer, modern standard |
| 2016 | Alacritty | Minimalist, GPU-accelerated rendering |
| 2017 | kitty | GPU-accelerated + built-in tabs/splits + image protocol |
| 2020 | WezTerm | GPU-accelerated, multiplexing built in, incl. over SSH |
| 2024 | Ghostty | Native platform integration, Zig |
| 2026 | Herdr | Multiplexer for AI coding agents: agent-state-aware panes |
| 2026 | tuios | Terminal window manager with daemon: agent grants, pane control, tmux shim |

