package Gipynit::CLPM3;

use 5.026000;
use strict;
use warnings;

use lib 'lib';

use Carp;
use Cwd;
use File::Basename ();
use JSON;
use Gipynit::CLPM3::Project;

our $VERSION = '0.01';
my $MAX_PREV_PROJECTS = 50;

#TODO:
# complex data structure is hard to read. Make it less complex, ala
# get_current_project_href
#
#TODO: write tests
# _store
# _read
# _is_valid_project
# unset_current_project
# go_previous_project
# set_current_project

# structure of data
#################################################################
# $self = { 'current' => 't',
#           'projects' => { 'pa' => { 'files' => { 'a' => '/home/dbradford/t3s/api_test.pl',
#                                                  'o' => '/home/dbradford/bin/onetime',
#                                                  'U' => '/opt/manfred/lib/Manfred/SimmCreate.pm' },
#                                     'commands' => { 'a' => { 'cmd' => '/home/dbradford/t3s/api_test.sh',
#                                                              'label' => '' },
#                                                     't' => { 'cmd' => './api_post.sh',
#                                                              'label' => '' } },
#                                     'label' => 'Manfred Test Gauntlet (TM)'
#                                   },
#                           'pad' => {etc},
#                         }
#         };

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
    my $utf8_encoded_json_text = $json_pretty->encode( $self->{data} );

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

    $self->{data} = $json->decode( $contents );

    return;
}

sub _is_valid_project {
    my ($self,$alias) = @_;
    if ( exists $self->{data}->{projects}->{$alias} ) {
        return 1;
    }
    return;
}

sub unset_current_project {
    my ($self) = @_;
    $self->{data}->{current} = '';
    return;
}

sub go_previous_project {
    my ($self) = @_;

    my $prev = pop @{$self->{data}->{previous}};
    while (defined $prev) {
        if ( $self->_is_valid_project($prev) ) {
            $self->set_current_project($prev);
            return;
        }
        $prev = pop @{$self->{data}->{previous}};
    }

    for my $project (keys %{$self->{data}->{projects}}) {
        if ( $self->_is_valid_project($project) ) {
            $self->set_current_project($project);
            return;
        }
    }

    $self->unset_current_project();
    return;
}


sub get_current_project_href {
    my ($self) = @_;

    return $self->{data}->{projects}->{ $self->{data}->{current} };
}

sub set_current_project {
    my ($self,$alias) = @_;

    if ( $self->{data}->{current} ) {
        push @{$self->{data}->{previous}}, $self->{data}->{current};
    }

    if ( $#{$self->{data}->{previous}} >= $MAX_PREV_PROJECTS ) {
        $#{$self->{data}->{previous}} = $MAX_PREV_PROJECTS - 1;
    }

    $self->{data}->{current} = $alias;
    return;
}

sub add_project {
    my ($self,%args) = @_;

    my $alias = $args{alias} || '';
    if ( $alias !~ /\w/ ) {
        croak qq{Bad alias "$alias" provided.};
    }

    my $description = $args{description};

    $self->{data}->{projects}->{$alias}->{description} = $description;
    $self->set_current_project($alias);
    $self->_store();
}

sub get_project {
    my ($self,$alias) = @_;

    my $project_data = $self->{data}->{projects}->{$alias};

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

    delete $self->{data}->{projects}->{$alias};
    $self->go_previous_project();

    $self->_store();
    return;
}

sub add_file {
    my ($self,%args) = @_;

    my $alias = $args{alias} || '';

    if ( $alias !~ /\w/ ) {
        croak qq{Bad alias "$alias" provided.};
    }

    my $path = Cwd::abs_path( $args{path} ) || '';

    if ( ! -r $path ) {
        croak qq{Can't read file "$path".};
    }

    my ($basename, $directory) = File::Basename::fileparse($path);
    my $current_project = $self->get_current_project_href();

    $current_project->{files}->{$alias} = {
         basename  => $basename,
         directory => $directory,
         path      => $path,
    };
    $self->_store();
}

sub remove_files {
    my ($self,@file_aliases) = @_;

    my $current_project = $self->get_current_project_href();

    for my $alias ( @file_aliases ) {
        delete $current_project->{files}->{$alias};
    }

    $self->_store();
    return;
}


sub get_files {
    my ($self) = @_;

    my $current_project = $self->get_current_project_href();

    return $current_project->{files};
}

# $gc->add_file(
#     alias => 'e',
#     path => "$TEST_DIRECTORY/elephant.pl",
# );
#
# my $files = $gc->get_files();
# $files = {
#     c => {
#         basename => 'CLPM3.pm',
#         directory => '/home/dbradford/clpm3/lib/Gipynit',
#         path => '/home/dbradford/clpm3/lib/Gipynit/CLPM3.pm',
#     },
# };


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

