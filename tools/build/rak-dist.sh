#!/usr/bin/env bash
# Make a self-contained rak release tarball, rak-VERSION.tar.gz.
#
# GitHub's automatic tarball of a tag is not enough to build rak: it leaves out
# nqp, MoarVM and their submodules, and rak pins commits of those between
# releases. This tarball holds, at the commits the tag pins:
#
#   rak-VERSION/                    the rak tree (git archive of the tag)
#   rak-VERSION/3rdparty/nqp-configure
#   rak-VERSION/nqp/                NQP_REVISION, with its nqp-configure
#   rak-VERSION/nqp/MoarVM/         nqp's MOAR_REVISION, with its submodules
#   rak-VERSION/gen/rak-dists/      the line editor tarballs (rak-line-editor-dists)
#
# It has no .git, so it records what git would have told the build:
# nqp/VERSION and nqp/MoarVM/VERSION get the full `git describe` of the
# pinned commits (Configure checks them against the pins), and RAK_SOURCE gets
# the repository URL and the tagged commit, for the irak banner.
#
# Build it with three Configure runs, MoarVM, then nqp, then rak: see the
# PKGBUILD in packaging/aur/rak/ and rak-plans/build/release.md.
#
# Usage: tools/build/rak-dist.sh [VERSION [OUTDIR]]
#   VERSION defaults to the RAK_VERSION file; the tag vVERSION must exist.
#   OUTDIR defaults to the current directory.
# Run from the root of a rak checkout whose nqp/ and nqp/MoarVM/ clones (made
# by Configure.pl --gen-nqp --gen-moar) hold the pinned commits.
set -euo pipefail

version=${1:-$(cat RAK_VERSION)}
outdir=$(cd "${2:-.}" && pwd)
tag=v$version
name=rak-$version
root=$(pwd)

git rev-parse -q --verify "refs/tags/$tag" >/dev/null ||
  { echo "rak-dist: no tag $tag" >&2; exit 1; }
[ "$(git show "$tag:RAK_VERSION")" = "$version" ] ||
  { echo "rak-dist: RAK_VERSION at $tag is not $version" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dest=$work/$name

# extract REPO COMMIT DIR: extract REPO's COMMIT into DIR.
extract() {
  local repo=$1 commit=$2 dir=$3
  mkdir -p "$dir"
  git -C "$repo" cat-file -e "$commit^{commit}" 2>/dev/null ||
    { echo "rak-dist: $repo lacks $commit; run Configure.pl or git fetch there" >&2; exit 1; }
  git -C "$repo" archive --format=tar "$commit" | tar -x -C "$dir"
}
# submodules REPO COMMIT DIR: extract REPO's submodules at COMMIT into DIR,
# each from its own clone under REPO.
submodules() {
  git -C "$1" ls-tree -r "$2" | awk '$2 == "commit" { print $3, $4 }' |
    while read -r sub path; do
      extract "$1/$path" "$sub" "$3/$path"
    done
}

commit=$(git rev-parse "$tag^{commit}")
extract "$root" "$commit" "$dest"
submodules "$root" "$commit" "$dest"

nqp_rev=$(git show "$tag:tools/templates/NQP_REVISION" | awk '{ print $1; exit }')
nqp_commit=$(git -C nqp rev-parse "$nqp_rev^{commit}")
extract "$root/nqp" "$nqp_commit" "$dest/nqp"
submodules "$root/nqp" "$nqp_commit" "$dest/nqp"
printf '%s\n' "$nqp_rev" > "$dest/nqp/VERSION"

moar_rev=$(git -C nqp show "$nqp_commit:tools/templates/MOAR_REVISION" | awk '{ print $1; exit }')
moar_commit=$(git -C nqp/MoarVM rev-parse "$moar_rev^{commit}")
extract "$root/nqp/MoarVM" "$moar_commit" "$dest/nqp/MoarVM"
submodules "$root/nqp/MoarVM" "$moar_commit" "$dest/nqp/MoarVM"
printf '%s\n' "$moar_rev" > "$dest/nqp/MoarVM/VERSION"

url=$(git remote get-url origin | sed -e 's|^git@\([^:]*\):|https://\1/|' -e 's|\.git$||')
printf '%s %s\n' "$url" "$(git rev-parse --short=10 "$commit")" > "$dest/RAK_SOURCE"

# The line editor tarballs, checked against their pinned sha256.
mkdir -p "$dest/gen/rak-dists"
grep -v '^#' tools/build/rak-line-editor-dists | while read -r dist sum path; do
  [ -n "$dist" ] || continue
  file=gen/rak-dists/$dist.tar.gz
  [ -f "$file" ] || curl -fsSL -o "$file" "https://360.zef.pm/$path"
  echo "$sum  $file" | sha256sum -c --quiet -
  cp "$file" "$dest/$file"
done

tar -C "$work" --sort=name --owner=0 --group=0 --numeric-owner \
  --mtime="@$(git log -1 --format=%ct "$commit")" -czf "$outdir/$name.tar.gz" "$name"
echo "$outdir/$name.tar.gz"
echo "  rak $commit, nqp $nqp_rev, MoarVM $moar_rev"
