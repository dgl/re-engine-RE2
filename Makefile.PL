use 5.010;
use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;

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

if($Config{usethreads} eq 'define') {
  if(defined $Config{i_pthread} && $Config{i_pthread} eq 'define') {
    $opt{DEFINE} = "-DHAVE_PTHREAD -pthread";
  } else {
    # For now this allows compilation under Win32/Strawberry
    # I'm not sure Perl needs thread safety from RE2 anyway as normally SVs
    # aren't shared but they might be..., needs some thought.
    $opt{DEFINE} = "-DNO_THREADS";
  }
} else {
  $opt{DEFINE} = "-DNO_THREADS";
}

# This is a bit hacky, RE2 makefile needs GNU make, for now we'll try to find
# it, ideally should rewrite the RE2 makefile to not need GNU make.
our $MAKE;
for my $make(qw(make gmake)) {
  if(qx{$make --version 2>&1} =~ /GNU Make/i) {
    $MAKE = $make;
    last;
  }
}

if(!$MAKE) {
  die "RE2 currently needs GNU Make, please install gmake.\n";
}

WriteMakefile(%opt);

sub MY::postamble {
  return <<MAKE_FRAG;

RE2_FLAGS = CC="\$(CC)" CXXFLAGS="\$(CCFLAGS) \$(CCCDLFLAGS) \$(OPTIMIZE) \$(DEFINE)" LDFLAGS="\$(OTHERLDFLAGS)"

re2/obj/libre2.a: re2/Makefile
	$MAKE -C re2 obj/libre2.a \$(RE2_FLAGS)

re2-tests:
	$MAKE -C re2 static-test \$(RE2_FLAGS)
 
MAKE_FRAG
}
