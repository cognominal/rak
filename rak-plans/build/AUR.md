# Packaging rak for the AUR

Status: a `rak-git` PKGBUILD is in [`packaging/aur/rak-git/`](../../packaging/aur/rak-git/).
It is not submitted yet; see [Before submitting](#before-submitting).

## What the AUR already has (checked 2026-11-24)

| Package | Version |
|---|---|
| `moarvm` | 2026.11 |
| `nqp` | 2026.11 |
| `rakudo` | 2026.11 |
| `rakudo-bin` | 2026.11_01 |
| `zef` | 1.1.3 |
| `rakudo-git` | 20181221 |

- `moarvm`, `nqp` and `rakudo` build the release tarballs with `--prefix=/usr`. Each
  depends on the one before; `rakudo` also installs `perl6-install-dist`.
- `rakudo-bin` is the rakudo.org binary build. It provides, and conflicts with, the
  three above and `zef`.
- `zef` depends on `rakudo`. `rakudo-git` is abandoned.

Nothing is called `rak` in the AUR or in the official repos. `pkgver()` uses
`git describe` against rak's own release tags, `v0.0.1` and up (`0.0.1.r5.gabc1234`).
Rakudo's tags aren't in the fork. A `rak` package, in
[`packaging/aur/rak/`](../../packaging/aur/rak/), builds a release from its tarball; it
is for local installs only for now ([Cutting a release](release.md)). Arch's official repos
have no Raku packages at all. `rlwrap` (0.48) is in `extra`.

One name clash exists outside the AUR: lizmat's `App::Rak`, installed with zef,
also puts a `rak` executable in Raku's `site/bin`. Someone with both on `PATH`
gets whichever comes first.

## Why rak can't depend on the AUR's rakudo stack

rak follows Rakudo main, which pins commits newer than the AUR's 2026.11 releases:
`tools/templates/NQP_REVISION` is `2026.11-12-g5fbb82e9a`, and nqp's `MOAR_REVISION` is
`2026.11-21-gfbae51aca`. That MoarVM has fixes rak needs, MoarVM#2087 and the NQP
bytecode write fix nqp#882, which no release carries yet. Even when a release catches
up, the pins move with every merge of Rakudo main. rak is also a fork of rakudo itself (the Rak frontend is compiled
into it), so it can't be a module on top of an existing rakudo.

So the package builds its own MoarVM, nqp and rakudo and installs all three under
`/usr/lib/rak`. Only `/usr/bin/rak` goes on `PATH`: a three-line launcher that sets
`RAKUDO_RAK_FRONTEND=1 RAKU_RAK_MODE=1` and runs `/usr/lib/rak/bin/rakudo`. So it
coexists with `rakudo`, `rakudo-bin`, `nqp` and `moarvm` and conflicts with none of them.

## The line editor is part of the package

irak is a main point of rak, and history and editing are what make it usable for
learning and trying rak. So the line editor is not optional. The REPL in irak mode tries
[Terminal::LineEditor](https://github.com/japhb/Terminal-LineEditor) first, because the
planned TAB / SHIFT-TAB navigation ([irak.md](../features/irak.md)) builds on it.

rlwrap was ruled out as the line editor: it sits outside the process, so it can't
complete from live Raku values, and it would take over TAB.

The AUR has no Raku module packages, so rak's own build installs Terminal::LineEditor and
its dependencies, pinned in `tools/build/rak-line-editor-dists`, from the zef CDN
(`360.zef.pm`). `make` unpacks them (`tools/build/rak-line-editor.pl`, which reuses
tarballs already in `gen/rak-dists/` and only warns if it can't download) and installs
them into the build tree's `vendor` repository; `make install` installs them into the
installed `vendor` repository. The PKGBUILD lists the tarballs as sources and copies them
into `gen/rak-dists/` in `prepare()`, so the build stays offline:

| distribution | version | license |
|---|---|---|
| Terminal::ANSIColor | 0.14 | MIT |
| Terminal::ANSIParser | 0.0.4 | Artistic-2.0 |
| Terminal-API (provides `Terminal::API`) | 1.0.5 | Artistic-2.0 |
| Terminal::Capabilities | 0.0.21 | Artistic-2.0 |
| Text::MiscUtils | 0.0.13 | Artistic-2.0 |
| Terminal::LineEditor | 0.0.23 | Artistic-2.0 |

They are all pure Raku. Terminal::API uses NativeCall for termios, which is why rak
mode has to be able to compile core's `NativeCall` (see below).

The build patches Terminal::LineEditor after unpacking it, with
`tools/build/rak-line-editor-patches/Terminal-LineEditor-0.0.23.patch`, from the rak
source tree: the patch is not a separate package source. It adds the `&on-finish`
callback that irak's double Enter needs, and a time limit on terminal queries. It is
not submitted to japhb/Terminal-LineEditor yet. Rakudo Star ships Terminal::LineEditor
0.0.23 unpatched, and not Terminal-API, Terminal::Capabilities or Text::MiscUtils (see
the [architectural note](../architectural-note.md#dependencies)).

irak keeps its own history file, `$XDG_STATE_HOME/rak/history`, since rak lines aren't
valid Raku; `RAKUDO_HIST` doesn't move it. The package creates no per-user folder: the
irak prompt makes its folders at startup ([startup file](../features/startup-file.md)).

## Building offline

AUR rules forbid network access outside the `source=` download. A normal
`Configure.pl --gen-moar --gen-nqp` clones nqp, MoarVM and their submodules from
GitHub, so the PKGBUILD:

1. lists every repository Configure clones (nqp, MoarVM, nqp-configure and MoarVM's
   nine submodules: libuv, dyncall, dynasm, libtommath, cmp, libatomic_ops, zmij,
   mimalloc, rapidhash) as `git+` sources, so makepkg mirrors them;
2. in `build()`, exports `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n`
   entries mapping each GitHub URL to its local mirror (`url.<mirror>.insteadOf`), and
   allowing git's file transport for submodules.

The rewrite has to go in the environment, not in each repo's `.git/config`: Configure
runs `git submodule sync`, which resets per-repo submodule URLs from `.gitmodules`.

The nqp and MoarVM sources aren't pinned to a commit: Configure checks out whatever
`NQP_REVISION` and `MOAR_REVISION` say, and makepkg's mirrors hold every commit.

## A relocatable build, installed in `$srcdir`

`--gen-moar` and `--gen-nqp` run `make install` for MoarVM and nqp *during
`Configure.pl`*, straight into the prefix, with no DESTDIR. With `--prefix=/usr/lib/rak`
the first test build tried to `mkdir /usr/lib/rak` on the real system; it failed only
because makepkg doesn't run as root. A non-relocatable build also compiles absolute paths
into its binaries (nqp-m's RUNPATH and its `nqp.moarvm` path), so a copy staged anywhere
else doesn't run.

So the PKGBUILD configures with `--relocatable` (passed down to nqp and MoarVM, which
then use `$ORIGIN`-relative RUNPATHs) and `--prefix=$srcdir/root`. `build()` runs
`make install` into that tree, which also installs the line editor into its `vendor`
repository. `package()` copies the tree to
`$pkgdir/usr/lib/rak`. rakudo.org's binary releases (`rakudo-bin`) are relocatable too.

`tools/build/install-rak-line-editor.raku` uses a plain Installation repository, because
`install-dist.raku --to=<dir> --for=vendor`, the staging mode distros use, doesn't work
here: when the target is also the running rakudo's own vendor repository, it leaves a
repo without a `version` file, and the next install dies in `upgrade-repository`.

## Two bugs this turned up: new sigils leaking into Raku code

Loading Terminal::LineEditor in irak failed twice. The rak frontend doesn't reuse the plain
frontend's precompiled modules, so it compiles them from source, core's `NativeCall`
included. Two rak-only rules in the grammars applied *whatever the file's extension*, so
`.rakumod` files were parsed with rak syntax:

- **`#word` comments.** `comment:sym<#>` read `#to` in NativeCall's `#to disting…` as an
  `#`-sigiled variable.
- **`~` as a sigil.** `token sigil` accepted `~` and `#`, so Terminal::LineEditor's
  `.then: { (~.result) ~~ … }` read `~.result` as a `~`-sigiled attribute (like
  `$.result`), not as prefix `~` on `$_.result`.

Both rules are now gated on `$*RAK-SEMANTICS`, in both grammar pairs: in rak code `#foo`
and `~foo` are variables; modules and `.raku` files parse as Raku. Both bugs also showed
under plain RakuAST (then `RAKUDO_RAKUAST=1`, the default since Rakudo 2026.11), where Rakudo Star 2026.08 parses the same code
fine:

```raku
say 1
  #c
  || 2;                                       # "Two terms in a row across lines"
say (1,2).map: { ~.succ };                    # "Variable ~.succ used where no 'self' is available"
```

Modules also stay Raku when `RAKU_RAK_MODE` is set (the `./rak` wrapper, irak): a
precompilation child (`RAKUDO_PRECOMP_WITH`) compiles as Raku, and so does an `EVAL`
whose caller is a module (a `#sources/` name, or a `.rakumod`/`.pm6`/`.pm` path, with
the ` (Name)` suffix stripped). An `EVAL` from a `.rak` file, `-e` or irak stays rak.
`t/02-rakudo/rak/019-module-eval.t` tests this.

More generally, under the rak frontend every module is compiled by the RakuAST grammar,
so any module that RakuAST can't parse yet won't load in rak.

## Before submitting

- Run `makepkg` end to end in a clean chroot (`extra-x86_64-build`) and run `namcap` on
  the result.
- Check `depends`: MoarVM links `zstd`; nothing else outside glibc is expected, but
  `namcap` will tell.
- Decide `pkgdesc` and the maintainer line.
- Regenerate `.SRCINFO` (`makepkg --printsrcinfo > .SRCINFO`) and push the PKGBUILD,
  the `rak` launcher and `.SRCINFO` to `ssh://aur@aur.archlinux.org/rak-git.git`.
- The `rak` package, built from release tarballs, can follow once 0.1 is released
  ([Cutting a release](release.md)).
