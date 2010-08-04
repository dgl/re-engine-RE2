use Test::More tests => 3;
BEGIN {
    require re::engine::RE2;
    re::engine::RE2->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::RE2->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
