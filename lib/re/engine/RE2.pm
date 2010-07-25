package re::engine::RE2;
use v5.10;

BEGIN {
  $re::engine::RE2::VERSION = "0.01_01";
}

use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN
{
    XSLoader::load __PACKAGE__, $VERSION;
}

sub import
{
    $^H{regcomp} = ENGINE;
}

sub unimport
{
    delete $^H{regcomp}
        if $^H{regcomp} == ENGINE;
}

1;

__END__

=head1 NAME 

re::engine::RE2 - RE2 regex engine

=head1 SYNOPSIS

    use re::engine::RE2;

    if ("Hello, world" =~ /Hello, (world)/) {
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

Replaces / arguments perl's regex engine in a given lexical scope with RE2.

Rather under development, this is just to show it's possible!

See L<http://github.com/dgl/re-engine-RE2>

=head1 AUTHORS

David Leadbeater E<lt>dgl[at]dgl[dot]cxE<gt>

=head1 COPYRIGHT

Copyright 2010 David Leadbeater.

Based on L<re::engine::PCRE>:

Copyright 2007 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

The original version was copyright 2006 Audrey Tang
E<lt>cpan@audreyt.orgE<gt> and Yves Orton.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
