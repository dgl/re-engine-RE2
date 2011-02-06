#!perl
use strict;
use Test::More tests => 3;

use re::engine::RE2 -max_mem => 8<<23; # 64MiB

my @test = 'aaa' ... 'zzz';
my $test_re = "(" . (join "|", @test) . ")";
$test_re = qr/$test_re/;

like "xxx", $test_re;
like "xlx", $test_re;
ok !("x1x" =~ $test_re);

