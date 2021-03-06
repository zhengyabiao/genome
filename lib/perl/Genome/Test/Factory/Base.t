#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok("Genome::Test::Factory::Base");

#package Genome::Foo;
#@ISA = (Genome::Test::Factory::Base);

#sub get_required_params {
#    my @r = ("fake");
#    return \@r;
#}

#my %provided;
#Genome::Foo->fill_in_missing_params(\%provided);
#check that this died with an error because there is no create_fake method on Foo

done_testing;
