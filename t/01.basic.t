use strict;
use Test::More tests => 7;
use re::engine::RE2;

ok("Hello, world" !~ /Goodbye, world/);
is($1, undef);

ok("Hello, world" =~ /Hello, (world)/);
is($1, 'world');

is qr/(Hello), (world)/->number_of_capture_groups, 2;

no re::engine::RE2;
is(eval '"Hello, world" =~ /^(?!Hello).*, (world)/', '');

if (fork) {
    ok(1);
} 

