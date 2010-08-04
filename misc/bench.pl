# Worst. Benchmark. Ever.
use Benchmark qw(cmpthese);

my $foo;
{
  open my $fh, "<", "/usr/share/doc/pcre/pcre.txt";
  $foo = join "", <$fh>;
}

cmpthese(-1, {
  re2 => sub {
    use re::engine::RE2;

    $foo =~ m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
  },
  re => sub {
    $foo =~ m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
  },
  re2_compiled => sub {
    use re::engine::RE2;

    my $re = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};

    $foo =~ $re;
  },
  re_compiled => sub {
    my $re = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};

    $foo =~ $re;
  }
});

