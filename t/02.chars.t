use strict;
use Test::More tests => 5;
use re::engine::RE2;

# Not UTF-8 in RE2 => fallback to Perl RE.
ok "\x{345}" =~ /\x{345}/;
is($1, undef);

ok "\x{ff}" =~ /\x{ff}/;

ok "\0" =~ /(\0)/;
is $1, "\0";

# XXX: utf8 vs latin1 tests
