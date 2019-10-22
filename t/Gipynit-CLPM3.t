# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Gipynit-CLPM3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use File::Path;
use Try::Tiny;

use Test::More tests => 26;
BEGIN { use_ok('Gipynit::CLPM3') }; #001

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Get a new object
my $gc = Gipynit::CLPM3->new();

$gc->test_init();
my $TEST_DIRECTORY = $gc->get_test_directory();

is(ref $gc, 'Gipynit::CLPM3', 'Got a valid object'); #002

$gc->add_project(
    alias       => 'a',
    description => 'Apple thingie',
);
$gc->add_project(
    alias       => 'c',
    description => 'Cat article',
);
$gc->add_project(
    alias       => 'd',
    description => 'Drum module',
);

my $test_letter = 's';
my $test_description = 'Shopping Cart';
$gc->add_project(
    alias       => $test_letter,
    description => $test_description,
);

my $shopping_cart = $gc->get_project($test_letter);
my $description = $shopping_cart->get_description();

is($description, $test_description, 'Description Matches'); #003

# Intentionally try to fail by adding without alias
my $error = '';
try {
    $gc->add_project();
}
catch {
    $error = $_;
};
like($error, qr{Bad alias}, 'Bad alias gives an error'); #004

$test_letter = 'b';
$test_description = 'Bumble Bee Game';
$gc->add_project(
    alias       => $test_letter,
    description => $test_description,
);

my $bumble_bee = $gc->get_project($test_letter);
$description = $bumble_bee->get_description();

is($description, $test_description, 'Description Matches'); #005

$gc->remove_project($test_letter);
$bumble_bee = $gc->get_project($test_letter);

is($bumble_bee, undef, 'Undefined because non-existent'); #006

# my $test_file = "$TEST_DIRECTORY/$file";
# touch('elephant.pl');
# touch('fire_engine.pm');
# touch('giraffes.txt');

$gc->add_file(
    alias => 'e',
    path => "$TEST_DIRECTORY/elephant.pl",
);

my $files = $gc->get_files();

is(ref $files, 'HASH', 'Get a hash of files'); #007
is(scalar keys %$files, 1, 'Only one file so far'); #008
is($files->{e}->{basename}, "elephant.pl", 'Correct file stored with correct alias: basename'); #009
is($files->{e}->{directory}, "$TEST_DIRECTORY/", 'Correct file stored with correct alias: directory'); #010
is($files->{e}->{path}, "$TEST_DIRECTORY/elephant.pl", 'Correct file stored with correct alias: path'); #011

$gc->add_file(
    alias => 'f',
    path => "$TEST_DIRECTORY/fire_engine.pm",
);

$files = $gc->get_files();

is(ref $files, 'HASH', 'Get a hash of files'); #012
is(scalar keys %$files, 2, 'Two files so far'); #013
is($files->{f}->{basename}, "fire_engine.pm", 'Correct file stored with correct alias: basename'); #014
is($files->{f}->{directory}, "$TEST_DIRECTORY/", 'Correct file stored with correct alias: directory'); #015
is($files->{f}->{path}, "$TEST_DIRECTORY/fire_engine.pm", 'Correct file stored with correct alias: path'); #016

$gc->add_file(
    alias => 'g',
    path => "$TEST_DIRECTORY/giraffes.txt",
);

$files = $gc->get_files();

is(ref $files, 'HASH', 'Get a hash of files'); #017
is(scalar keys %$files, 3, 'Three files'); #018
is($files->{g}->{basename}, "giraffes.txt", 'Correct file stored with correct alias: basename'); #019
is($files->{g}->{directory}, "$TEST_DIRECTORY/", 'Correct file stored with correct alias: directory'); #020
is($files->{g}->{path}, "$TEST_DIRECTORY/giraffes.txt", 'Correct file stored with correct alias: path'); #021

$gc->remove_files('e','g');

$files = $gc->get_files();

is(ref $files, 'HASH', 'Get a hash of files'); #022
is(scalar keys %$files, 1, 'Back to one file'); #023
is($files->{f}->{basename}, "fire_engine.pm", 'Correct file stored with correct alias: basename'); #024
is($files->{f}->{directory}, "$TEST_DIRECTORY/", 'Correct file stored with correct alias: directory'); #025
is($files->{f}->{path}, "$TEST_DIRECTORY/fire_engine.pm", 'Correct file stored with correct alias: path'); #026

$gc->test_cleanup();

__END__

TODO: test bad behavior like:
-----------------------------
[ ] overwriting a current file
[ ] non-existent file

[ ] Command Line Program Managers (clpm) v2.0.0
[ ] Help commands:
[ ]             z  - this listing
[ ] Organization commands:
[ ]             f  - manage files
[ ]                 examples:
[ ]                 show list of files:    $ f
[ ]                 edit file 1, 3, and L: $ f 13L
[ ]                 edit all files:        $ fa
[ ]                 add file to the list : $ f , /tmp/a.dmb /etc/hosts /etc/passwd
[ ]                 add file with label L: $ f L /tmp/a.dmb
[ ]                 remove file 1, 3, L  : $ f -13L
[ ]             x  - manage commands (same basic format as f)
[ ]                 examples:
[ ]                 show list of cmds:     $ x
[ ]                 run cmd 1, 3, and L:   $ x 13L
[ ]                 edit cmd 1, 3, and L:  $ x .13L
[ ]                 run all cmds:          $ xa
[ ]                 add cmd to the list :  $ x , 'echo hey' 'Optional Label'
[ ]                     NOTE: surround command with quotes
[ ]                 add cmd with label L:  $ x L 'echo howdy; echo there' 'Optional Label'
[ ]                 remove cmd 1, 3, L  :  $ x -13L
[ ]             p  - change project/view list of projects
[ ]                 show project list:     $ p
[ ]                 switch to project:     $ p myproj
[ ]                 remove project:        $ p -myproj
[ ] Current project: c

