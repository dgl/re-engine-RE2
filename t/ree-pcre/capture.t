use strict;

use Test::More tests => 20;

use re::engine::RE2;

unless ("eep aoeu 420 eek" =~ /(.)(.)(.)(.) ([0-9]+)/) {
    fail "didn't match";
} else {
    is($`, "eep ");
    is($', " eek");
    is($&, "aoeu 420", '$&');

    is($1, "a", '$1 = a');
    is($2, "o", '$2 = o');
    is($3, "e", '$3 = e');
    is($4, "u", '$4 = u');
    is($5, "420", '$5 = 420');
    is($6, undef, '$6 = undef');
    is($640, undef, '$640 = undef');
}

unless ("aoeuhtns" =~ /(.)(.)(.)(.)/g) {
    fail "didn't match";
} else {
    is($1, "a");
    is($2, "o");
    is($3, "e");
    is($4, "u");
    is($5, undef);
    is($6, undef);
    is($7, undef);
    is($8, undef);
}

my ($a, $b) = "ab" =~ /(.)/g;
is($a, "a");
is($b, "b");

