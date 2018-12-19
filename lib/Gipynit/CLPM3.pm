package Gipynit::CLPM3;

use 5.026000;
use strict;
use warnings;

use lib 'lib';

use Carp;
use JSON;
use Gipynit::CLPM3::Project;

our $VERSION = '0.01';

sub new {
    my ($class,%args) = @_;
    my $CLPM3_DIR = $ENV{CLPM3_DIR} || "$ENV{HOME}/.clpm3";
    my $json = JSON->new->allow_nonref;

    my $self = {
        store_file => $ENV{CLPM3_STORE} || "$CLPM3_DIR/projects.json",
        json => $json,
    };
    bless $self, $class;
    $self->_read();
    return $self;
}

sub _store {
    my ($self,%args) = @_;

    my $json = $self->{json};
    my $store_file = $self->{store_file};

    my $ofh = IO::File->new($store_file, '>');
    if ( !defined $ofh ) {
        warn "Can't write to project file $store_file.\n";
        return;
    }

    my $json_pretty = $json->pretty;
    my $utf8_encoded_json_text = $json_pretty->encode( $self->{projects} );

    print $ofh $utf8_encoded_json_text;
    $ofh->close;
    return;
}

sub _read {
    my ($self,%args) = @_;

    my $json = $self->{json};
    my $store_file = $self->{store_file};

    if ( ! -f $store_file ) {
        # Try to write a blank file if none exists
        $self->_store();
    }
    my $ifh = IO::File->new($store_file, '<');
    die "Failed open: $!" if (!defined $ifh);

    my $contents = do { local $/; <$ifh> };
    $ifh->close;

    $self->{projects} = $json->decode( $contents );

    return;
}

sub add_project {
    my ($self,%args) = @_;

    my $alias = $args{alias} || '';
    #TODO: test
    if ( $alias !~ /\w/ ) {
        croak qq{Bad alias "$alias" provided.};
    }

    my $description = $args{description};

    $self->{projects}->{$alias}->{description} = $description;
    $self->_store();
}

sub get_project {
    my ($self,$alias) = @_;

    my $project_data = $self->{projects}->{$alias};

    if ( ref $project_data ne 'HASH' ) {
        return;
    }

    my $project = Gipynit::CLPM3::Project->new(
        alias => $alias,
        description => $project_data->{description},
    );
    return $project;
}

sub remove_project {
    my ($self,$alias) = @_;

    delete $self->{projects}->{$alias};

    $self->_store();
    return;
}

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
