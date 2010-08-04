use strict;
use Test::More tests => 1;
use re::engine::RE2;

my @a = "abcdef" =~ /(..)/g;
is_deeply \@a, [qw[ab cd ef]];

