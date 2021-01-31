use strict;
use Test::More tests => 6;
use re::engine::RE2;

ok("Hello, world" !~ /Goodbye, world/);
is($1, undef);

ok("Hello, world" =~ /Hello, (world)/);
is($1, 'world');

no re::engine::RE2;
is(eval '"Hello, world" =~ /(?<=Ms|Mo), (world)/', undef);

if (fork) {
    ok(1);
} 

