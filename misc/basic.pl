use Benchmark qw(cmpthese :hireswallclock);

my $foo = "foo bar baz";

cmpthese(-1, {
  re2 => sub {
    use re::engine::RE2;

    $foo =~ /foo/;
    $foo =~ /foox/;
  },
  re => sub {
    $foo =~ /foo/;
    $foo =~ /foox/;
  }
});

