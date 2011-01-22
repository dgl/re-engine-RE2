package MY;

# This is a bit hacky, RE2 makefile needs GNU make, for now we'll try to find
# it, ideally should rewrite the RE2 makefile to not need GNU make.
for my $make(qw(make gmake)) {
  if(qx{$make --version 2>&1} =~ /GNU Make/i) {
    $MAKE = $make;
    last;
  }
}

if(!$MAKE) {
  die "RE2 currently needs GNU Make, please install gmake.\n";
}

sub postamble {
  return <<MAKE_FRAG;
re2/obj/libre2.a: re2/Makefile
	$MAKE -C re2 obj/libre2.a
MAKE_FRAG
}

1;
