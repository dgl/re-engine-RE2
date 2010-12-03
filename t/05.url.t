#!perl
use Test::More tests => 3;
use re::engine::RE2;

# From http://daringfireball.net/2010/07/improved_regex_for_matching_urls
my $re = qr{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))};

my $res = "this is a URL: http://github.com" =~ $re;

ok $res;
is $1, "http://github.com";

my @url = "this is a URL: http://github.com" =~ $re;
is_deeply \@url, ["http://github.com", (undef) x 4];

