use Test::More tests => 2;
use re::engine::RE2;

my $re = qr/aoeu/;

isa_ok($re, "re::engine::RE2");
is("$re", "aoeu");
