#!/usr/bin/env perl
# Fetch and unpack the distributions listed in rak-line-editor-dists, for
# install-rak-line-editor.raku. A tarball already in DIR is used as is, which
# is how an offline build (the AUR package) supplies them. Each tarball is
# checked against its sha256 and unpacked into DIR/<name>/.
#
# A download failure is only a warning: rak still builds, and irak says how
# to install the line editor by hand.
#
# Usage: rak-line-editor.pl MANIFEST DIR
use strict;
use warnings;
use Digest::SHA;
use File::Path qw(make_path remove_tree);

my ($manifest, $dir) = @ARGV;
die "usage: $0 MANIFEST DIR\n" unless defined $dir;
make_path($dir);

open my $fh, '<', $manifest or die "$manifest: $!\n";
my @dists = map { [split] } grep { /\S/ && !/^\s*#/ } <$fh>;
close $fh;

for my $d (@dists) {
    my ($name, $sha, $path) = @$d;
    my $tarball = "$dir/$name.tar.gz";

    unless (-e $tarball) {
        my $url = "https://360.zef.pm/$path";
        print "    Fetching $name\n";
        if (system('curl', '-fsSL', '-o', "$tarball.part", $url) != 0) {
            unlink "$tarball.part";
            warn "WARNING: could not fetch $url; irak will have no line editor\n";
            exit 0;
        }
        rename "$tarball.part", $tarball or die "$tarball: $!\n";
    }

    my $got = Digest::SHA->new(256)->addfile($tarball)->hexdigest;
    die "$tarball: sha256 $got, expected $sha\n" unless $got eq $sha;

    remove_tree("$dir/$name");
    make_path("$dir/$name");
    system('tar', '-xzf', $tarball, '-C', "$dir/$name", '--strip-components=1') == 0
        or die "could not unpack $tarball\n";
}
