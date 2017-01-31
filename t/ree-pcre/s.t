use strict;
use Test::More tests => 10;
use re::engine::RE2;

local $_;

$_ = "ab";
s/a//;
is($_, 'b', q(s/a//; 'ab' => 'b'));

$_ = "abc";
s/.//g;
is($_, '', q(s/.//g; 'abc' => ''));

$_ = "abcd";
s/.//g;
is($_, '', q(s/.//g; 'abcd' => ''));

$_ = "abcdefg";
s/.//g;
is($_, '', q(s/.//g; 'abcdefg' => ''));

$_ = "aabbc";
s/..//g;
is($_, 'c', q(s/..//g; 'aabbc' => 'c'));

$_ = "a";
s/./1+1/eg;
is($_, "2", q(s/./1+1/eg; 'a' => '2'));

$_ = "abc";
s/./1+1/eg;
is($_, "222", q(s/./1+1/eg; 'abc' => '222'));

$_ = "3";
s/(.)/$1+1/eg;
is($_, "4", q(s/(.)/$1+1/eg; '3' => '4'));

$_ = "123";
s/(.)/$1+1/eg;
is($_, "234", q(s/(.)/$1+1/eg; '123' => '234'));

$_ = 'abc123xyz';
s/([0-9]+)/$1*2/e;     # yields 'abc246xyz'
is($_, 'abc246xyz', q(s/([0-9]+)/$1*2/e; 'abc123xyz' => ''abc246xyz'));
