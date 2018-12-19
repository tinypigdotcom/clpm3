# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Gipynit-CLPM3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use File::Path;
use Try::Tiny;

use Test::More tests => 6;
BEGIN { use_ok('Gipynit::CLPM3') }; #001

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Remove and create test data directory so we're starting from scratch
my $TEST_DIRECTORY = "$ENV{HOME}/.clpm3test";
File::Path::remove_tree($TEST_DIRECTORY);
if ( -d $TEST_DIRECTORY ) {
    die "Remove directory failed for $TEST_DIRECTORY: $!";
}

mkdir $TEST_DIRECTORY;
if ( ! -d $TEST_DIRECTORY ) {
    die "Create directory failed for $TEST_DIRECTORY: $!";
}

$ENV{CLPM3_DIR} = $TEST_DIRECTORY;

# Get a new object
my $gc = Gipynit::CLPM3->new();
is(ref $gc, 'Gipynit::CLPM3', 'Got a valid object'); #002

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

#Command Line Program Managers (clpm) v2.0.0
#Help commands:
#            z  - this listing
#Organization commands:
#            f  - manage files
#                examples:
#                show list of files:    $ f
#                edit file 1, 3, and L: $ f 13L
#                edit all files:        $ fa
#                add file to the list : $ f , /tmp/a.dmb /etc/hosts /etc/passwd
#                add file with label L: $ f L /tmp/a.dmb
#                remove file 1, 3, L  : $ f -13L
#            x  - manage commands (same basic format as f)
#                examples:
#                show list of cmds:     $ x
#                run cmd 1, 3, and L:   $ x 13L
#                edit cmd 1, 3, and L:  $ x .13L
#                run all cmds:          $ xa
#                add cmd to the list :  $ x , 'echo hey' 'Optional Label'
#                    NOTE: surround command with quotes
#                add cmd with label L:  $ x L 'echo howdy; echo there' 'Optional Label'
#                remove cmd 1, 3, L  :  $ x -13L
#            p  - change project/view list of projects
#                show project list:     $ p
#                switch to project:     $ p myproj
#                remove project:        $ p -myproj
#Current project: c

