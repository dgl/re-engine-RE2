=pod

=cut

use Test::More tests => 9;
use re::engine::RE2;

# Croaks on 32
my $subexp = 9;
my $s = "a" x $subexp;
my $r = ("(.)" x $subexp);

if ($s =~ $r) {
    #diag("matched $s against $r");
    for my $num (1 .. $subexp) {
        is($$num, "a", "\$$num eq a");
    }
} else {
    fail "no match";
}
