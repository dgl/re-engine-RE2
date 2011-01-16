use strict;
use Test::More tests => 1;
use re::engine::RE2;

{
  use utf8;

  # Match UTF-8 LHS against UTF-8 RHS
  ok "£" =~ /^£$/;
}

