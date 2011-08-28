use Test::More;
use re::engine::RE2 -strict => 1;

is eval q{ /(?x:foo)/ }, undef, "Strict mode enforced";
like $@, qr/invalid perl operator/;

{
  use re::engine::RE2 -never_nl => 1;

  ok "foo" =~ /.../;
  ok !("fo\no" =~ /..\n./);
  ok !("fo\no" =~ /.../);
  ok "f\noo" =~ /../;
}

{
  # first without longest_match
  ok "abcd" =~ /(a|abc)/;
  ok $1 eq "a";
  ok "abcd" =~ /(abc|a)/;
  ok $1 eq "abc";
}

{
  use re::engine::RE2 -longest_match => 1;
  ok "abcd" =~ /(a|abc)/;
  ok $1 eq "abc";
  ok "abcd" =~ /(abc|a)/;
  ok $1 eq "abc";
}

done_testing;
