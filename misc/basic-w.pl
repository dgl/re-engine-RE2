use Benchmark qw(cmpthese :hireswallclock);

my $foo = "foo bar baz " x 10;

cmpthese(-1, {
  re => sub {
    $foo =~ /\w{3}/;
    $foo =~ /\w{3}\s*\w+/;
    $foo =~ / \w+? \w+/;
    $foo =~ /\w+ \w+$/;
  },
  re2 => sub {
    use re::engine::RE2;

    $foo =~ /\w{3}/;
    $foo =~ /\w{3}\s*\w+/;
    $foo =~ / \w+? \w+/;
    $foo =~ /\w+ \w+$/;
  },
  Oniguruma => sub {
    use re::engine::Oniguruma;

    $foo =~ /\w{3}/;
    $foo =~ /\w{3}\s*\w+/;
    $foo =~ / \w+? \w+/;
    $foo =~ /\w+ \w+$/;
  },
});

