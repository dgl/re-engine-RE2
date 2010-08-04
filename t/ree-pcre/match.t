use Test::More tests => 2;
use re::engine::RE2;

"a" =~ /b/ ? fail "invalid match" : pass "didn't match on invalid match";
"a" =~ /a/ ? pass "valid match"   : fail "didn't match on valid match";
