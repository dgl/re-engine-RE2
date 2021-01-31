use strict;
use Test::More tests => 7;
use re::engine::RE2;

ok("Hello, world" !~ /Goodbye, world/);
is($1, undef);

ok("Hello, world" =~ /Hello, (world)/);
is($1, 'world');

ok(!eval '"Hello, world" =~ /(?{ }), (world)/');
no re::engine::RE2;
ok( eval '"Hello, world" =~ /(?{ }), (world)/');

if (fork) {
    ok(1);
} 

