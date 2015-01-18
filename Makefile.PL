use 5.012;
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

if(eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
  $opt{META_MERGE} = {
    resources => {
      repository => 'https://github.com/dgl/re-engine-RE2'
    }
  }
}

# If the user didn't explicitly provide optimisation settings, we'll try to do
# it ourselves, but only for gcc.

my $cc = (map +(/^CC=(.*)/i), @ARGV)[0] || $Config{cc};
if(!grep(/^OPTIMIZE=/i, @ARGV)
    and my $gcc_version = gcc_version($cc)) {
  say "Compiling on gcc $gcc_version";
  my $optimize = $Config{optimize};

  if($gcc_version) {
    $optimize =~ s/-O[s0-2]/-O3/ and say "Optimize level set to -O3";
  }

  # Attempt to work out if we have a gcc that is likely to support -flto.
  # This is probably a lot of work for a minimal gain, but it's worth a try.
  if($gcc_version >= 4.5) {
    my $try_optimize = "$optimize -flto";
    # Try to use this flag
    if(gcc_try(cc => $cc, %opt, OPTIMIZE => $try_optimize)) {
      $optimize = $try_optimize;
    }

    # gcc 4.9 needs this otherwise it gets rid of nearly everything in libre2.a.
    $try_optimize = "$optimize -ffat-lto-objects";
    if(gcc_try(cc => $cc, %opt, OPTIMIZE => $try_optimize)) {
      $optimize = $try_optimize;
    }
  }

  say "OPTIMIZE is now: $optimize";
  $opt{OPTIMIZE} = $optimize;
}

if(defined $Config{usethreads} && $Config{usethreads} eq 'define') {
  if(defined $Config{i_pthread} && $Config{i_pthread} eq 'define') {
    $opt{DEFINE} = "-DHAVE_PTHREAD -pthread";
  } else {
    # For now this allows compilation under Win32/Strawberry, but might cause weird crashes on thread
    # destruction...
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

sub gcc_version {
  my($cc) = @_;
  my $gcc_out = qx{$cc -v 2>&1};
  # Just the first two digits
  $gcc_out =~ /gcc version (\d+\.\d+)/ ? $1 : 0;
}

# This is highly gcc and unix specific, but that's where I care about
# optimising this anyway.
sub gcc_try {
  my(%opts) = @_;
  system "$opts{cc} $opts{CCFLAGS} $opts{OPTIMIZE} -c -o /dev/null /dev/null >/dev/null 2>&1";
  not $?;
}

sub MY::postamble {
  return <<MAKE_FRAG;

RE2_FLAGS = CC="\$(CC)" CXXFLAGS="\$(CCFLAGS) \$(CCCDLFLAGS) \$(OPTIMIZE) \$(DEFINE)" LDFLAGS="\$(OTHERLDFLAGS) \$(LDLOADLIBS)"

re2/obj/libre2.a: re2/Makefile
	$MAKE -C re2 obj/libre2.a \$(RE2_FLAGS)

re2-tests:
	$MAKE -C re2 static-test \$(RE2_FLAGS) LDFLAGS="\$(OTHERLDFLAGS) \$(LDLOADLIBS) -lm -lpthread"

MAKE_FRAG
}
