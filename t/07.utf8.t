use strict;
use Test::More tests => 3;
use re::engine::RE2;

{
  use utf8;

  # Match UTF-8 LHS against UTF-8 RHS
  ok "£" =~ /^£$/;
}

{
  use utf8;
  local $TODO = "Need to implement hex encoding for Latin-1";

  ok "\x{a3}" =~ /£/;
}

{
  use utf8;
  local $TODO = "Need to use alternative regexp";

  ok "£" =~ /^\x{a3}$/;
}

