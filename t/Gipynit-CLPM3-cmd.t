# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Gipynit-CLPM3-cmd.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Capture::Tiny ':all';
use Data::Dumper;
use Test::More tests => 3; # tt
use Try::Tiny;

BEGIN { use_ok('Gipynit::CLPM3') }; #001

# Get a new object
my $gc = Gipynit::CLPM3->new();

$gc->test_init();
my $TEST_DIRECTORY = $gc->get_test_directory();

$ENV{PATH} = "./bin/:$ENV{PATH}";

my $bin_p = 'bin/p';
my $bin_f = 'bin/f';

sub stderr {
    my ($cmd) = @_;
    my ($stdout, $stderr, @result) = capture {
        system $cmd;
    };
    return $stderr;
}

my $help = stderr("$bin_f --help");
like($help, qr{Usage}, 'Got usage message'); #002
like($help, qr{Command Line Project Manager}, 'Got usage message'); #003

__END__

my $json = JSON->new->allow_nonref; 
my $command = 'bin/store.pl -t';

unlink "$ENV{HOME}/test_store.db";

sub get_command_json {
    my ($cmd) = @_;
    my ($stdout, $stderr, @result) = capture {
        system "$command $cmd";
    };
    my $data = $json->decode( $stdout );
    return $data;
}

sub stderr {
    my ($cmd) = @_;
    my ($stdout, $stderr, @result) = capture {
        system "$command $cmd";
    };
    return $stderr;
}

my $help = stderr('help');
like($help, qr{Usage}, 'Got usage message'); #002
like($help, qr{Building database tables}, 'Got building database tables message'); #002

my %store;
sub new_store {
    my ($cmd_store) = @_;
    my $data = get_command_json(qq{new "$cmd_store"});
    is($data->{name},$cmd_store,'Got the same store name back');
    like($data->{store_id},qr{^\d+$},'store_id is an integer');
    $store{$cmd_store} = $data->{store_id};
}

my @stores_a = (
    "Costco",
    "Dollar General",
    "Fred's",
    "Ollie's Bargain Outlet",
    "Target",
);

for (@stores_a) {
    new_store($_);
}

my $repeat = stderr('new "Costco"'); # same one again
like($repeat, qr{Store already exists}, 'Got already exists warning');

# ====== ADD ==================================================================
my $data = get_command_json(qq{add 1 000002062259 1});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_command_json(qq{avail 000002062259});
is($data->[0]->{quantity},1,'Correct quantity');
is($data->[0]->{store_id},1,'Correct store_id');

# add 2 to same store / upc
$data = get_command_json(qq{add 1 000002062259 2});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_command_json(qq{avail 000002062259});
is($data->[0]->{quantity},3,'Correct quantity');
is($data->[0]->{store_id},1,'Correct store_id');

# add 3 to same store / upc
$data = get_command_json(qq{add 1 000002062259 3});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_command_json(qq{avail 000002062259});
is($data->[0]->{quantity},6,'Correct quantity');
is($data->[0]->{store_id},1,'Correct store_id');

# add
$data = get_command_json(qq{add 2 000002062259 1});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

sub get_available {
    my ($upc) = @_;
    my $data = get_command_json(qq{avail $upc});

    my %reorg;
    for (@$data) {
        $reorg{$_->{store_id}} = $_->{quantity};
    }

    return \%reorg;
}

sub get_reserved {
    my ($upc) = @_;
    my $data = get_command_json(qq{reserv $upc});

    my %reorg;
    for (@$data) {
        $reorg{$_->{store_id}} = $_->{quantity};
    }

    return \%reorg;
}

my @quantities = (
    [1,6],
    [2,1]
);

sub test_available_quantities {
    my ($upc) = @_;

    my $data = get_available($upc);

    is(scalar keys %$data,scalar @quantities,'Only n values');
    for(@quantities) {
        is($data->{$_->[0]},$_->[1],'Correct quantity');
    }
}

test_available_quantities('000002062259');

$data = get_command_json(qq{add 3 000002062259 2});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

push @quantities, [3,2];
test_available_quantities('000002062259');

$data = get_command_json(qq{add 4 000002062259 3});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

push @quantities, [4,3];
test_available_quantities('000002062259');

# ====== BAD INPUT ============================================================

my $bad_input = stderr(''); # no command
like($bad_input, qr{Invalid subcommand}, 'Check for Invalid subcommand message');
like($bad_input, qr{Usage}, 'Check for Usage message');

$bad_input = stderr('add'); # missing additional data
like($bad_input, qr{Invalid input}, 'Check for Invalid subcommand message');
like($bad_input, qr{Usage}, 'Check for Usage message');

$bad_input = stderr('add fish'); # trash data
like($bad_input, qr{Invalid input}, 'Check for Invalid input message');
like($bad_input, qr{Usage}, 'Check for Usage message');

$bad_input = stderr('add 2 3 4'); # trash upc
like($bad_input, qr{Invalid UPC}, 'Check for Invalid input message');
like($bad_input, qr{Usage}, 'Check for Usage message');


$bad_input = stderr('add 0 000002062259 1'); # add to bad store id
like($bad_input, qr{No such store ID}, 'Check for No such store ID message');

$bad_input = stderr('add 5 000038649813 -1'); # add negative
like($bad_input, qr{Invalid input}, 'Check for Invalid input message');
like($bad_input, qr{Usage}, 'Check for Usage message');


# ====== MORE ADDS ============================================================

@quantities = (
    [5,5],
);

# --- add ---
$data = get_command_json(qq{add 5 000038649813 5});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},5,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 5 000038649813 7});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},12,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 5 000038649813 11});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},23,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 1 291000277602 1});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('291000277602');
is(scalar keys %$data,1,'Only 1 values');
is($data->{1},1,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 2 094530200535 2});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('094530200535');
is(scalar keys %$data,1,'Only 1 values');
is($data->{2},2,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 3 881738003521 3});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('881738003521');
is(scalar keys %$data,1,'Only 1 values');
is($data->{3},3,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 4 090431086025 4});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('090431086025');
is(scalar keys %$data,1,'Only 1 values');
is($data->{4},4,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 5 090431086025 5});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('090431086025');
is(scalar keys %$data,2,'Only 2 values');
is($data->{4},4,'Correct quantity');
is($data->{5},5,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 4 291000277602 6});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('291000277602');
is(scalar keys %$data,2,'Only 2 values');
is($data->{1},1,'Correct quantity');
is($data->{4},6,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 3 094530200535 7});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('094530200535');
is(scalar keys %$data,2,'Only 2 values');
is($data->{3},7,'Correct quantity');
is($data->{2},2,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 2 881738003521 8});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('881738003521');
is(scalar keys %$data,2,'Only 1 values');
is($data->{3},3,'Correct quantity');
is($data->{2},8,'Correct quantity');

# --- add ---
$data = get_command_json(qq{add 1 090431086025 9});
is(ref $data, 'ARRAY', 'Add of inventory returns array');

$data = get_available('090431086025');
is(scalar keys %$data,3,'Only 3 values');
is($data->{1},9,'Correct quantity');
is($data->{4},4,'Correct quantity');
is($data->{5},5,'Correct quantity');

# ====== ORDER ================================================================

# --- order ---
$data = get_command_json(qq{order 1 000002062259 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

is(scalar @{$data->{items}},1,'Only 1 values');
is($data->{items}->[0]->{store_id},1,'store ID');
is($data->{items}->[0]->{quantity},1,'Quantity');
is($data->{items}->[0]->{upc},'000002062259','UPC');

# --- check order ---
$data = get_command_json(qq{order 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

is(scalar @{$data->{items}},1,'Only 1 values');
is($data->{items}->[0]->{store_id},1,'store ID');
is($data->{items}->[0]->{quantity},1,'Quantity');
is($data->{items}->[0]->{upc},'000002062259','UPC');

# --- available post order ---
$data = get_available('000002062259');
is(scalar keys %$data,4,'Only 4 values');
is($data->{1},5,'Correct quantity');
is($data->{2},1,'Correct quantity');
is($data->{3},2,'Correct quantity');
is($data->{4},3,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000002062259');
is(scalar keys %$data,1,'Only 1 values');
is($data->{1},1,'Correct quantity');


# --- order ---
$data = get_command_json(qq{order 1 1 000002062259 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

is(scalar @{$data->{items}},1,'Only 1 values');
is($data->{items}->[0]->{store_id},1,'store ID');
is($data->{items}->[0]->{quantity},2,'Quantity');
is($data->{items}->[0]->{upc},'000002062259','UPC');


# --- available post order ---
$data = get_available('000002062259');
is(scalar keys %$data,4,'Only 4 values');
is($data->{1},4,'Correct quantity');
is($data->{2},1,'Correct quantity');
is($data->{3},2,'Correct quantity');
is($data->{4},3,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000002062259');
is(scalar keys %$data,1,'Only 1 values');
is($data->{1},2,'Correct quantity');


# --- order too much ---
$data = stderr('order 1 1 000002062259 5');
like($data,qr{Not enough inventory},'Not enough inventory message');


# --- available should be the same ---
$data = get_available('000002062259');
is(scalar keys %$data,4,'Only 4 values');
is($data->{1},4,'Correct quantity');
is($data->{2},1,'Correct quantity');
is($data->{3},2,'Correct quantity');
is($data->{4},3,'Correct quantity');


# --- reserved should be the same ---
$data = get_reserved('000002062259');
is(scalar keys %$data,1,'Only 1 values');
is($data->{1},2,'Correct quantity');


# --- order all the rest ---
$data = get_command_json(qq{order 1 1 000002062259 4});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

is(scalar @{$data->{items}},1,'Only 1 values');
is($data->{items}->[0]->{store_id},1,'store ID');
is($data->{items}->[0]->{quantity},6,'Quantity');
is($data->{items}->[0]->{upc},'000002062259','UPC');


# --- available post order ---
$data = get_available('000002062259');
is(scalar keys %$data,4,'Only 4 values');
is($data->{1},0,'Correct quantity');
is($data->{2},1,'Correct quantity');
is($data->{3},2,'Correct quantity');
is($data->{4},3,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000002062259');
is(scalar keys %$data,1,'Only 1 values');
is($data->{1},6,'Correct quantity');

# --- available pre order ---
$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},23,'Correct quantity');


sub get_order_items {
    my ($data) = @_;
    my $items = $data->{items};

    my %reorg;
    for (@$items) {
        $reorg{$_->{store_id}}->{$_->{upc}} = $_->{quantity};
    }

    return \%reorg;
}


# --- order a different upc ---
$data = get_command_json(qq{order 1 5 000038649813 7});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

my $reorg_items = get_order_items($data);
is(scalar keys %$reorg_items,2,'Only 2 values');
is($reorg_items->{1}->{'000002062259'},6,'Quantity');
is($reorg_items->{5}->{'000038649813'},7,'Quantity');


# --- available post order ---
$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},16,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},7,'Correct quantity');


# --- order a different upc ---
$data = get_command_json(qq{order 1 4 000002062259 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

$reorg_items = get_order_items($data);
is(scalar keys %$reorg_items,3,'Only 3 values');
is($reorg_items->{1}->{'000002062259'},6,'Quantity');
is($reorg_items->{4}->{'000002062259'},1,'Quantity');
is($reorg_items->{5}->{'000038649813'},7,'Quantity');


# --- check order ---
$data = get_command_json(qq{order 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Open',q{Hasn't shipped});

$reorg_items = get_order_items($data);
is(scalar keys %$reorg_items,3,'Only 3 values');
is($reorg_items->{1}->{'000002062259'},6,'Quantity');
is($reorg_items->{4}->{'000002062259'},1,'Quantity');
is($reorg_items->{5}->{'000038649813'},7,'Quantity');


# --- ship order ---
$data = get_command_json(qq{ship 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Shipped',q{HAS shipped});

$reorg_items = get_order_items($data);
is(scalar keys %$reorg_items,3,'Only 3 values');
is($reorg_items->{1}->{'000002062259'},6,'Quantity');
is($reorg_items->{4}->{'000002062259'},1,'Quantity');
is($reorg_items->{5}->{'000038649813'},7,'Quantity');


# --- check order ---
$data = get_command_json(qq{order 1});
is($data->{shipment_id},1,'Got shipment_id');
is($data->{status},'Shipped',q{HAS shipped});

$reorg_items = get_order_items($data);
is(scalar keys %$reorg_items,3,'Only 3 values');
is($reorg_items->{1}->{'000002062259'},6,'Quantity');
is($reorg_items->{4}->{'000002062259'},1,'Quantity');
is($reorg_items->{5}->{'000038649813'},7,'Quantity');


# --- available post order ---
$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},16,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000038649813');
is(scalar keys %$data,0,'Only 0 values');


# --- order too much ---
$data = stderr('order 1 4 000002062259 1'); # invalid add to shipped order
like($data,qr{Nonexistent shipping_id or has already shipped},'Nonexistent shipping_id or has already shipped');


# --- available post ship order ---
$data = get_available('000002062259');
is(scalar keys %$data,4,'Only 4 values');
is($data->{1},0,'Correct quantity');
is($data->{2},1,'Correct quantity');
is($data->{3},2,'Correct quantity');
is($data->{4},2,'Correct quantity');


# --- reserved post ship order ---
$data = get_available('000038649813');
is(scalar keys %$data,1,'Only 1 values');
is($data->{5},16,'Correct quantity');


# --- reserved post order ---
$data = get_reserved('000002062259');
is(scalar keys %$data,0,'Only 0 values');


