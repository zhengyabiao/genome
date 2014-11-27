#!/usr/bin/env genome-perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Sub::Install qw(reinstall_sub);
use above 'Genome';
use Genome::Utility::Test qw(compare_ok);
use Genome::VariantReporting::Framework::TestHelpers qw(
    get_translation_provider
    get_reference_build
    test_dag_xml
    test_dag_execute
    get_test_dir
);
use Genome::VariantReporting::Framework::Plan::TestHelpers qw(
    set_what_interpreter_x_requires
);

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

my $pkg = 'Genome::VariantReporting::Suite::Vep::Expert';
use_ok($pkg) || die;
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('experts', $pkg->name), $pkg);

my $VERSION = 12; # Bump these each time test data changes
my $RESOURCE_VERSION = 2;

my $test_dir = get_test_dir($pkg, $VERSION);

my $expert = $pkg->create();
my $dag = $expert->dag();
test_dag_xml($dag, __FILE__);

set_what_interpreter_x_requires('vep');
my $variant_type = 'snvs';
my $expected_vcf = File::Spec->join($test_dir, "expected_$variant_type.vcf.gz");
my $provider = get_translation_provider(version => $RESOURCE_VERSION);
my $reference_sequence_build => get_reference_build(version => $RESOURCE_VERSION);

my $feature_list_cmd = Genome::FeatureList::Command::Create->create(
    reference => $reference_sequence_build,
    file_path => File::Spec->join($test_dir, "feature_list.bed"),
    format => "true-BED",
    content_type => "roi",
    name => "test",
);
my $feature_list = $feature_list_cmd->execute;
$provider->translations({%{$provider->translations}, feature_list_ids => {TEST => $feature_list->id}});


my $input_vcf = File::Spec->join($test_dir, "$variant_type.vcf.gz");
test_dag_execute($dag, $expected_vcf, $input_vcf, $provider, $variant_type, __FILE__);

done_testing();
