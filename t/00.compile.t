use Test::More tests => 2;

my $pkg = 're::engine::RE2';
use_ok $pkg;
isa_ok(bless([] => $pkg), 'Regexp');
