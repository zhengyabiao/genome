#!/usr/bin/env genome-perl
use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above 'Genome';
use Test::More;
use Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanResult;
use lib File::Basename::dirname(File::Spec->rel2abs(__FILE__));
use chimerascan_test_setup "setup";

my $chimerascan_version = '0.4.5';
my ($alignment_result, $annotation_build) = setup(test_data_version => 4,
        chimerascan_version => $chimerascan_version);

*Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanResult::_staging_disk_usage
    = sub { return 40 * 1024 };


my $no_bam_result = Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanResult->get_or_create(
    alignment_result => $alignment_result,
    version => $chimerascan_version,
    detector_params => "--bowtie-version=0.12.7 --reuse-bam 0",
    annotation_build => $annotation_build,
);
isa_ok($no_bam_result, "Genome::Model::RnaSeq::DetectFusionsResult::ChimerascanResult");

done_testing();

1;
