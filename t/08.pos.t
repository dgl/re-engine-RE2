#!perl
use Test::More tests => 18;

my $str = "foo bar baz";
my @expected = split / /, $str;

{
  use re::engine::RE2 -strict => 1;

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

  $str =~ /(?P<a>\w+) (?P<b>\w+) (?P<c>\w+)/ && pass "Matched";
  is_deeply \%+, { a => "foo", b => "bar", c => "baz" };

  # Captures retained?
  ok !($str =~ /(?P<a>\w+) meh (?P<c>\w+)/);
  is_deeply \%+, { a => "foo", b => "bar", c => "baz" };

  ok $str =~ /(?P<a>\w+) (?P<d>\w+)/;
  is_deeply \%+, { a => "foo", d => "bar" };
}
