use strict;
use Test::More tests => 5;
use re::engine::RE2;

ok "a\nb" !~ /^b$/;
ok "a\nb" =~ /^b/m;
ok "a\nb" =~ /(?m)^b$/;
ok "a\nb" =~ /^a\nb$/m;

{
  local $TODO = "Need to implement /s option passing for RE2";
  ok "a\nb" =~ /^a.b$/s;
}

