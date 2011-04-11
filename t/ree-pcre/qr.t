use Test::More tests => 3;
use re::engine::RE2;

my $re = qr/aoeu/;

isa_ok($re, "re::engine::RE2");
is("$re", "(?-ims:aoeu)");
is(qr/aoeu/ims, "(?ims:aoeu)");
