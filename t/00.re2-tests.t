use Test::More;
require './MY.pm';
no warnings;

for(qx{$MY::MAKE -C re2 static-test}) {
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

done_testing;
