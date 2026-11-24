use Test;
use nqp;

# The build records the rak version, repository URL and HEAD sha1 into the
# build config (tools/build/gen-rak-build-info.pl), for the irak banner.

plan 5;

my $config := nqp::gethllsym('default', 'SysConfig').rakudo-build-config;
my $url    := nqp::atkey($config, 'rak-repo-url');
my $head   := nqp::atkey($config, 'rak-head');

ok nqp::existskey($config, 'rak-head'), 'build config has rak-head';
like $url,  / ^ [ 'https://' \S+ ]? $ /,                  'rak-repo-url is an https URL, or empty';
like nqp::atkey($config, 'rak-version'), / ^ \d+ '.' \d+ '.' \d+ [ '-' \d+ '-g' <xdigit>+ ]? $ /,
  'rak-version is a release version, maybe past its tag';
like $head, / ^ [ <xdigit> ** 10 '-dirty'? ]? $ /, 'rak-head is a short sha1, maybe -dirty, or empty';

# Under the rak frontend (the ./rak wrapper sets it), --version names rak too.
my $version = nqp::hllize(nqp::atkey($config, 'rak-version'));
my $out = run($*EXECUTABLE, '--version', :out, :err).out.slurp(:close);
ok !$version || $out.contains("\nrak v$version.\n"), '--version names the rak version';
