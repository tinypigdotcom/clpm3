package Gipynit::CLPM3::Project;

use 5.026000;
use strict;
use warnings;

our $VERSION = '0.01';

# TODO: separate test file
sub new {
    my ($class,%args) = @_;

    my $self = {
        alias => $args{alias},
        description => $args{description},
    };
    bless $self, $class;
    return $self;
}

sub set_description {
    my ($self,$description) = @_;

    $self->{description} = $description;
    return;
}

sub get_description {
    my ($self) = @_;

    return $self->{description};
}

#$gc->add_project(
#    alias       => $test_letter,
#    description => $test_description,
#);
#
#my $shopping_cart = $gc->get_project($test_letter);
#my $description = $shopping_cart->get_description();
#
#is($description, $test_description, 'Description Matches'); #003


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gipynit::CLPM3 - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Gipynit::CLPM3;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Gipynit::CLPM3, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

David Bradford, E<lt>dbradford@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by David Bradford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
