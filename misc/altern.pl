#!perl

sub compile_re2_utf8 {
  use re::engine::RE2 -max_mem => 8<<23;
  my $re = $_[0];
  utf8::upgrade $re;
  return qr/$re/;
}

my $re = compile_re2_utf8(q/./);

my @a = aaa ... zzz;

my $a = "(" . join("|", @a) . ")";
my $a_re = compile_re2_utf8($a);

use Benchmark qw(cmpthese);

cmpthese(undef, {
  re2 => sub {
    "foo" =~ $a_re
  },
  re => sub {
    "foo" =~ /$a/
  }
});

