#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above 'Genome';
use Test::Exception;
use Test::More;
use Genome::VariantReporting::Suite::BamReadcount::TestHelper qw(create_default_entry
     create_no_readcount_entry
     create_deletion_entry);

my $pkg = 'Genome::VariantReporting::Suite::BamReadcount::MinCoverageFilter';
use_ok($pkg);
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('filters', $pkg->name), $pkg);

my %pass = (
    G => 1,
    C => 1,
    AA => 1,
);

my %fail = (
    G => 0,
    C => 0,
    AA => 0,
);

my %autopass_s1 = (
    G => 1,
    C => 0,
    AA => 0,
);

subtest "pass" => sub {
    my $min_coverage = 300;
    my $filter = $pkg->create(min_coverage => $min_coverage, sample_name => "S1");
    lives_ok(sub {$filter->validate}, "Filter validates");
    my $entry = create_default_entry();
    is_deeply({$filter->filter_entry($entry)}, \%pass, "Entry passes filter with min_coverage $min_coverage");

    $entry = create_no_readcount_entry();
    is_deeply({$filter->filter_entry($entry)}, \%autopass_s1, "Entry without coverage automatically passes filter within the sample genotype with min_coverage $min_coverage");
};

subtest "fail" => sub {
    my $min_coverage = 400;
    my $filter = $pkg->create(min_coverage => $min_coverage, sample_name => "S1");
    lives_ok(sub {$filter->validate}, "Filter validates");

    my $entry = create_default_entry();
    is_deeply({$filter->filter_entry($entry)}, \%fail, "Entry does not pass filter with min_coverage $min_coverage");
};

subtest "insertion" => sub {
    my $min_coverage = 300;
    my $filter = $pkg->create(min_coverage => $min_coverage, sample_name => "S4");
    lives_ok(sub {$filter->validate}, "Filter validates");
    my $entry = create_default_entry();
    is_deeply({$filter->filter_entry($entry)}, \%pass, "Entry passes filter with min_coverage $min_coverage");
};

subtest "deletion" => sub {
    my $min_coverage = 300;
    my $pass = {
        A => 1,
    };
    my $filter = $pkg->create(min_coverage => $min_coverage, sample_name => "S1");
    lives_ok(sub {$filter->validate}, "Filter validates");
    my $entry = create_deletion_entry();
    is_deeply({$filter->filter_entry($entry)}, $pass, "Entry passes filter with min_coverage $min_coverage");
};

subtest "under-specified parameters" => sub {
    my $filter = $pkg->create();
    dies_ok(sub {$filter->validate}, "Filter without enough parameters does not validate");
};

done_testing();
