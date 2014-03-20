#! /gsc/bin/perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above 'Genome';
use Test::More;
use Genome::Test::Factory::Model::ImportedReferenceSequence;
use Genome::Test::Factory::Build;

my $class = 'Genome::InstrumentData::Command::RefineReads::ClipOverlap';
my $input_result_class = 'Genome::InstrumentData::AlignmentResult::Merged';
my $tool_class = 'Genome::Model::Tools::BamUtil::ClipOverlap';
use_ok($class) or die;
use_ok($tool_class) or die;
use_ok($input_result_class) or die;

my $clip_overlap_version = "1.0.11";


my $reference_model = Genome::Test::Factory::Model::ImportedReferenceSequence->setup_object();
my $test_dir = Genome::Sys->create_temp_directory;
my $reference_build = Genome::Test::Factory::Build->setup_object(
    model_id => $reference_model->id,
    data_directory => $test_dir,
);
my $bam_source = $input_result_class->__define__(reference_build => $reference_build,);

# We are not testing the tool, so make the execute just create an output file
Sub::Install::reinstall_sub({
    into => $tool_class,
    as => 'execute',
    code => sub { my $self = shift; Genome::Sys->copy_file($self->input_bam, $self->output_bam); },
});

# make a file with some content
my $bam_path = Genome::Sys->create_temp_file_path;
my $bfh = Genome::Sys->open_file_for_writing($bam_path);
$bfh->print('Some data\n');
$bfh->close;
Sub::Install::reinstall_sub({
    into => $input_result_class,
    as => 'bam_path',
    code => sub { return $bam_path; },
});

my %params = (
    version => $clip_overlap_version,
    bam_source => $bam_source,
);

my $clip_overlap = $class->create(%params);

ok($clip_overlap, "Created a $class object");
ok(!$clip_overlap->shortcut, 'shortcut fails as expected');

# Execute
ok($clip_overlap->execute, "Executed $class object");
my $clip_overlap_result = $clip_overlap->result;

# TODO check software result users? Is this applicable? Should our code do something with this?

# Now, shortcut should work
my $clip_overlap_shortcut = $class->create(%params);
ok($clip_overlap_shortcut, "Created a $class object");
$DB::single=1;
ok($clip_overlap_shortcut->shortcut, 'shortcut worked as expected');
is($clip_overlap_shortcut->result, $clip_overlap->result, 'software result matches between shortcut and create');

# test sub _get_or_create_clip_overlap_result {
# test sub _params_for_result {

done_testing();
