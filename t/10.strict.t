use Test::More;
use re::engine::RE2 -strict => 1;

is eval q{ /(?x:foo)/ }, undef, "Strict mode enforced";
like $@, qr/invalid perl operator/;

done_testing;
