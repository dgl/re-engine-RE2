use v5.10;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# TODO: Optionally use system libre2, via ExtUtils::Liblist?

system "cd re2 && make obj/so/libre2.so"
  || die "Compliation of RE2 failed, see above messages\n";

my @objects = (qw(RE2.o re2_xs.o), glob "re2/obj/so/{util,re2}/*.o");

# TODO: Use ExtUtils::CppGuess rather than current hack of relying on gcc to
# figure it out (and the LIBS hack below).

WriteMakefile(
  NAME          => 're::engine::RE2',
  AUTHOR        => 'David Leadbeater <dgl@dgl.cx>',
  VERSION_FROM  => 'lib/re/engine/RE2.pm',
  ABSTRACT_FROM => 'lib/re/engine/RE2.pm',
  LICENSE       => 'perl',
  INC           => '-Ire2',
  PMLIBDIRS     => ["lib"],
  OBJECT        => join(" ", @objects),
  LIBS          => "-lstdc++ -lpthread"
);

