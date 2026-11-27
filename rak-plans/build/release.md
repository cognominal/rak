# Cutting a rak release

rak versions are its own, `0.0.1` and up, unrelated to Rakudo's `2026.11`-style
versions (see [ROADMAP.md](../ROADMAP.md) for what each version is meant to hold).
A release is a `vVERSION` git tag, a GitHub release with a self-contained source
tarball, and the `rak` package in [`packaging/aur/rak/`](../../packaging/aur/rak/),
which builds from that tarball. Releases before 0.1 are GitHub *pre-releases*, and the
package is installed locally only, not submitted to the AUR.

## Where the version lives

- **`RAK_VERSION`** at the repo root holds the version of the next or current release.
  `VERSION` stays Rakudo's: upstream merges and `Configure.pl` own it.
- **`tools/build/gen-rak-build-info.pl`** records `rak-version` in the build config:
  `git describe --tags --match 'v[0-9]*'` without its `v` (`0.0.1`, or
  `0.0.1-5-gabc1234` five commits past the tag), else `RAK_VERSION`.
- **irak's banner** shows it on its second line: `rak v0.0.1, <repo URL> @ <HEAD>`.
- **`rak --version`** adds a line `rak v0.0.1.` under the rak frontend. Plain
  `rakudo --version` is unchanged.
- **`rak-git`'s `pkgver()`** is `git describe` against the same tags
  (`0.0.1.r5.gabc1234`).

`t/02-rakudo/rak/011-build-info.t` and `012-irak-banner.t` test these.

## The tarball

GitHub's automatic tarball of a tag can't be built: it leaves out nqp, MoarVM and
their submodules, and rak pins commits of them between releases, which no nqp or
MoarVM release tarball matches. `tools/build/rak-dist.sh` makes `rak-VERSION.tar.gz`,
which holds:

- the rak tree at the tag, with its `3rdparty/nqp-configure`;
- `nqp/` at `NQP_REVISION`, and `nqp/MoarVM/` at nqp's `MOAR_REVISION`, each with its
  submodules;
- `gen/rak-dists/`, the line editor tarballs, checked against their sha256 in
  `tools/build/rak-line-editor-dists`.

It has no `.git`, so it writes down what git would have told the build:

- `nqp/VERSION` and `nqp/MoarVM/VERSION` hold the pinned `git describe` strings,
  since Configure checks each component against the pins (MoarVM `2026.11` would be
  "too old" for `2026.11-21-gfbae51aca`);
- `RAK_SOURCE` holds the repository URL and the tagged commit, for the irak banner.

The script reads the commits from the checkout's `nqp/` and `nqp/MoarVM/` clones, the
ones `Configure.pl --gen-nqp --gen-moar` made, so run it after a build of the tag.

## Building from the tarball

Without `.git`, `Configure.pl --gen-nqp --gen-moar` can't fetch, so the three parts are
built in turn, each installed into the prefix the next one uses:

```sh
tar -xzf rak-0.0.1.tar.gz && cd rak-0.0.1
P=$HOME/rak-0.0.1         # any prefix; --relocatable lets the tree move later
(cd nqp/MoarVM && perl Configure.pl --prefix=$P --relocatable && make && make install)
(cd nqp && perl Configure.pl --backends=moar --prefix=$P --relocatable \
   --with-moar=$P/bin/moar && make && make install)
perl Configure.pl --backends=moar --prefix=$P --relocatable --with-nqp=$P/bin/nqp
make && make install
RAKUDO_RAK_FRONTEND=1 RAKU_RAK_MODE=1 $P/bin/rakudo   # irak
```

The `rak` PKGBUILD does the same in `build()`, with `$srcdir/root` as the prefix, and
installs the tree as `/usr/lib/rak`.

## Steps

1. Set `RAK_VERSION`, and `pkgver` in `packaging/aur/rak/PKGBUILD`.
2. Write the release notes, `rak-docs/releases/VERSION.md`, and update
   [ROADMAP.md](../ROADMAP.md) and [status.md](../status.md).
3. Check: `make rak-test`, and `make test` against the previous baseline.
4. Commit, then tag: `git tag -a vVERSION -m 'rak VERSION'`.
5. Make the tarball: `tools/build/rak-dist.sh VERSION OUTDIR`.
6. Test it: copy it into `packaging/aur/rak/` (makepkg uses a source file already
   there instead of downloading it) and run `makepkg -f` there. Then
   `makepkg -si`, or `pacman -U` the package, and run `rak`.
7. Push the branch and the tag: `git push origin rak vVERSION`.
8. Publish: `gh release create vVERSION --repo cognominal/rak --prerelease
   --title 'rak VERSION' --notes-file rak-docs/releases/VERSION.md
   OUTDIR/rak-VERSION.tar.gz`.
9. Put the tarball's sha256 in the PKGBUILD's `sha256sums`, regenerate `.SRCINFO`
   (`makepkg --printsrcinfo > .SRCINFO`), commit and push.
