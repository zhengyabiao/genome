#!/gsc/bin/perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok("Genome::Model::Tools::Annotate::Sv::Combine");

my $base_dir = $ENV{GENOME_TEST_INPUTS}."/Genome-Model-Tools-Annotate-Sv-Combine";
my $version  = 2;
my $data_dir = "$base_dir/v$version";

#2 add cancer_gene_list to transcripts for human

my $temp_file = Genome::Sys->create_temp_file_path;
my $cmd = Genome::Model::Tools::Annotate::Sv::Combine->create(
    input_file => "$data_dir/in.svs",
    output_file => $temp_file,
    annotation_build_id => 131184146,
    annotator_list      => ['Transcripts', 'Dbsnp', 'Segdup', 'Dbvar'],
    transcripts_print_flanking_genes => 1,
    transcripts_cancer_gene_list     => join("/",Genome::Sys->dbpath("cancer-gene-list/human",1),"Cancer_genes.csv"),
    dbvar_breakpoint_wiggle_room => 300,
);

ok($cmd, "Created command");

ok($cmd->execute, "Command executed successfully");

my $expected_file = "$data_dir/expected.out";
ok(-s $temp_file, "Output file created");
ok(-s $expected_file, "Expected file exists");
my $expected = `cat $expected_file | sort`;
my $actual = `cat $temp_file | sort`;
my $diff = Genome::Sys->diff_text_vs_text($expected, $actual);
ok(!$diff, "No diffs with expected output");
done_testing;
