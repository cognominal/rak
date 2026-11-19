# Install the line editor irak needs into a repository, from the
# distributions rak-line-editor.pl unpacked. Run by the build-tree rakudo,
# like install-core-dist.raku, so it works before rakudo is installed and
# under a DESTDIR.
#
# Usage: install-rak-line-editor.raku MANIFEST DIR REPO-PREFIX [STAMP]
#
# STAMP, if given, is written on success, so make can skip the step next time.

my ($manifest, $dir, $prefix, $stamp) = @*ARGS;

my @names = $manifest.IO.lines.grep({ .trim && !.trim.starts-with('#') }).map(*.words.head);

# Nothing unpacked (the download failed): leave irak without a line editor.
unless @names.all.&{ $dir.IO.add($_).add('META6.json').e } {
    note "    Line editor not installed: run with network access, or see $manifest";
    exit;
}

# A plain Installation repository, not Staging: Staging leaves no `version`
# file when the target is also a repository of the running rakudo.
my $repo := CompUnit::Repository::Installation.new(
    :$prefix,
    :next-repo(CompUnit::RepositoryRegistry.repository-for-name('core')),
);

# No precompilation here: the build-tree rakudo finds core modules such as
# NativeCall in lib/, not in the core repository, so precompiled files would
# point at the wrong NativeCall once installed. The rak frontend compiles
# modules separately anyway; they are compiled on first use.
for @names -> $name {
    $repo.install(Distribution::Path.new($dir.IO.add($name)), :force, :!precompile);
}

$stamp.IO.spurt('') if $stamp;
note "    Installed the irak line editor ({+@names} distributions) in {now - INIT now} seconds";
