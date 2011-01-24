use Test::More;
no warnings;

my $make = $ENV{MAKE} || "make";

my @results = qx{$make re2-tests};

for(@results) {
  if(my($test, $result, $diag) = $_ =~ /^(obj[^ ]+)\s+(PASS|FAIL)(.*)/) {
    if($result eq 'PASS') {
      pass $test;
    } else {
      fail "$test$diag";

      if($diag =~ /output in (.*)/) {
        my $file = "re2/$1";
        open my $log_fh, "<", $file or do { diag "$file: $!"; next };
        diag <$log_fh>;
      }
    }
  }
}

if("@results" !~ /PASS|FAIL/) {
  diag @results;
  plan skip_all => "Unable to compile RE2 tests for some reason";
}

done_testing;
