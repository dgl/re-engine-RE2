use strict;
use Test::More tests => 2;
use re::engine::RE2;

my $re = qr/^(?:a|b).*/;

my @range = $re->possible_match_range;
is $range[0], "a";
is $range[1], "c";

