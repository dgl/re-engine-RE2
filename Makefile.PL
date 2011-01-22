use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;

require "./MY.pm";

# TODO: Optionally use system libre2, via ExtUtils::Liblist?

my @objects = qw(RE2.o re2_xs.o re2/obj/libre2.a);

my $guess = ExtUtils::CppGuess->new;

my %opt = (
  NAME               => 're::engine::RE2',
  AUTHOR             => 'David Leadbeater <dgl@dgl.cx>',
  VERSION_FROM       => 'lib/re/engine/RE2.pm',
  ABSTRACT_FROM      => 'lib/re/engine/RE2.pm',
  LICENSE            => 'perl',
  INC                => '-Ire2',
  PMLIBDIRS          => ["lib"],
  OBJECT             => join(" ", @objects),
  test               => {TESTS => 't/*.t t/ree-pcre/*.t'},
  CONFIGURE_REQUIRES => {
    "ExtUtils::CppGuess" => 0,
    "Test::More"         => 0.88,
  },
  $guess->makemaker_options
);

$opt{LIBS} .= "-lpthread";

WriteMakefile(%opt);
