package Gipynit::CLPM3;

use 5.026000;
use strict;
use warnings;

use lib 'lib';

use Carp;
use Cwd;
use File::Basename ();
use File::Path ();
use JSON;
use Gipynit::CLPM3::Project;
use Getopt::Long;

BEGIN { $| = 1 }

our $VERSION = '0.01';
my $MAX_PREV_PROJECTS = 50;

my $PROG = File::Basename::basename($0);
my $ERR_EXIT = 2;
my $TEST_DIRECTORY = "$ENV{HOME}/.clpm3test";

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

    File::Path::make_path( File::Basename::dirname($store_file) );

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

sub usage_top {
    my ($self) = @_;
    warn "Usage: $PROG FILE1 FILE2\n";
}

sub short_usage {
    my ($self) = @_;
    $self->usage_top();
    warn "Try '$PROG --help' for more information.\n";
}

sub errout {
    my ($self) = @_;
    my $message = join( ' ', @_ );
    warn "$PROG: $message\n";
    $self->short_usage();
    exit $ERR_EXIT;
}

sub usage {
    my ($self) = @_;
    $self->usage_top();
    warn <<EOF;
Command Line Project Manager (clpm) $VERSION
Help commands:
            z  - this listing
Organization commands:
            f  - manage files
                examples:
                show list of files:    \$ f
                edit file 1, 3, and L: \$ f 13L
                edit all files:        \$ fa
                add file to the list : \$ f , /tmp/a.dmb /etc/hosts /etc/passwd
                add file with label L: \$ f L /tmp/a.dmb
                remove file 1, 3, L  : \$ f -13L
            x  - manage commands (same basic format as f)
                examples:
                show list of cmds:     \$ x
                run cmd 1, 3, and L:   \$ x 13L
                edit cmd 1, 3, and L:  \$ x .13L
                run all cmds:          \$ xa
                add cmd to the list :  \$ x , 'echo hey' 'Optional Label'
                    NOTE: surround command with quotes
                add cmd with label L:  \$ x L 'echo howdy; echo there' 'Optional Label'
                remove cmd 1, 3, L  :  \$ x -13L
            p  - change project/view list of projects
                show project list:     \$ p
                switch to project:     \$ p myproj
                remove project:        \$ p -myproj
Current project: c
EOF
    return;
}

sub do_short_usage {
    my ($self) = @_;
    $self->short_usage();
    exit $ERR_EXIT;
}

sub version {
    my ($self) = @_;
    warn "$PROG $VERSION\n";
    return;
}

sub run {
    my ($self) = @_;

    my $h        = 0;
    my $help     = 0;
    my $version  = 0;

    Getopt::Long::Configure ("bundling");

    my %options = (
        "help"   => \$help,
        "version" => \$version,
    );

    # Explicitly add single letter version of each option to allow bundling
    my ($key, $value);
    my %temp = %options;
    while (($key,$value) = each %temp) {
        my $letter = $key;
        $letter =~ s/(\w)\w*/$1/;
        $options{$letter} = $value;
    }
    # Fix-ups from previous routine
    $options{h} = \$h;

    GetOptions(%options) or errout("Error in command line arguments");

    if    ($help)     { $self->usage(); exit    }
    elsif ($h)        { $self->do_short_usage() }
    elsif ($version)  { $self->version(); exit  }
}

# !!! NOTE !!!
# Below here, it's not Object-Oriented. Test code needs to be outside the
# object because it needs to do some initiation before new() runs.

sub touch {
    my ($file) = @_;

    my $test_file = "$TEST_DIRECTORY/$file";
    open(my $ofh, ">", $test_file)
        or die "Can't open < $test_file: $!";
    close $ofh;
}

sub remove_test_directory {
    File::Path::remove_tree($TEST_DIRECTORY);
    if ( -d $TEST_DIRECTORY ) {
        die "Remove directory failed for $TEST_DIRECTORY: $!";
    }
}

sub test_init {
    # Remove and create test data directory so we're starting from scratch
    remove_test_directory();

    File::Path::make_path($TEST_DIRECTORY);
    if ( ! -d $TEST_DIRECTORY ) {
        die "Create directory failed for $TEST_DIRECTORY: $!";
    }

    touch('elephant.pl');
    touch('fire_engine.pm');
    touch('giraffes.txt');

    $ENV{CLPM3_DIR} = $TEST_DIRECTORY;
}

sub test_cleanup {
    remove_test_directory();
}

sub get_test_directory {
    return $TEST_DIRECTORY;
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

