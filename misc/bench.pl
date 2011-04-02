# Worst. Benchmark. Ever.
use Benchmark qw(cmpthese);

my $foo;
{
  open my $fh, "<", $ARGV[0] || "/usr/share/doc/pcre/pcre.txt";
  $foo = join "", <$fh>;
}

my $re_prere = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
my $re_prere2;
{
  use re::engine::RE2;
  $re_prere2 = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
}

cmpthese(-1, {
  Oniguruma => sub {
    use re::engine::Oniguruma;

    $foo =~ m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
  },
  re2 => sub {
    use re::engine::RE2;

    $foo =~ m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
  },
  re => sub {
    $foo =~ m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};
  },
  re2_recompiled => sub {
    use re::engine::RE2;

    my $re = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};

    $foo =~ $re;
  },
  re_recompiled => sub {
    my $re = qr{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^ @]+)};

    $foo =~ $re;
  },
  re2_precompiled => sub {
    $foo =~ /$re_prere2/o;
  },
  re_precompiled => sub {

    $foo =~ /$re_prere/o;
  }
});

