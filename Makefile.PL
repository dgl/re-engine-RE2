use 5.010;
use strict;
use warnings;

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
  CONFIGURE_REQUIRES => { "ExtUtils::CppGuess" => 0 },
  $guess->makemaker_options
);

$opt{LIBS} .= "-lpthread";

# This is a bit hacky, RE2 makefile needs GNU make, for now we'll try to find
# it, ideally should rewrite the RE2 makefile to not need GNU make.
for my $make(qw(make gmake)) {
  if(qx{$make --version 2>&1} =~ /GNU Make/i) {
    $opt{postamble} = { make => $make };
    last;
  }
}

if(!$opt{postamble} || !$opt{postamble}{make}) {
  die "RE2 currently needs GNU Make, please install gmake.\n";
}

WriteMakefile(%opt);

package MY;

sub postamble {
  my($class, %postamble) = @_;
  return <<MAKE_FRAG;
re2/obj/libre2.a: re2/Makefile
	$postamble{make} -C re2 obj/libre2.a
MAKE_FRAG
}

