use Test;
use nqp;

# The build records the rak repository URL and HEAD sha1 into the build
# config (tools/build/gen-rak-build-info.pl), for the irak banner.

plan 3;

my $config := nqp::gethllsym('default', 'SysConfig').rakudo-build-config;
my $url    := nqp::atkey($config, 'rak-repo-url');
my $head   := nqp::atkey($config, 'rak-head');

ok nqp::existskey($config, 'rak-head'), 'build config has rak-head';
like $url,  / ^ [ 'https://' \S+ ]? $ /,                  'rak-repo-url is an https URL, or empty';
like $head, / ^ [ <xdigit> ** 10 '-dirty'? ]? $ /, 'rak-head is a short sha1, maybe -dirty, or empty';
