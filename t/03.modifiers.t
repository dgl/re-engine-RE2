BEGIN { %ENV = () }

use strict;
use Test::More tests => 1;
use re::engine::RE2;

my @a = "abcdef" =~ /(..)/g;
open my $fh, ">", "/tmp/fail";
print $fh Dumper(\@a);use Data::Dumper;

is_deeply \@a, [qw[ab cd ef]];

