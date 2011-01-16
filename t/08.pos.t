#!perl
use Test::More tests => 12;

my $str = "foo bar baz";
my @expected = split / /, $str;

{
  use re::engine::RE2;

  my @matches = $str =~ /(\w+)/g;
  is_deeply \@matches, \@expected;
  is pos $str, undef;

  my $i = 0;
  while($str =~ /(\w+)/g) {
    is $1, $expected[$i++];
    is pos $str, $i-1+3*$i;
  }

  pos $str = 2;
  ok ~~($str =~ /\b(\w+)/g);
  is $1, $expected[1];
  ok ~~($str =~ /\b(\w+)/g);
  is $1, $expected[2];
}
