#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT}               = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above "Genome";
use Test::More;

use Genome::Utility::Test;

use Genome::Model::ClinSeq::TestData;

my $pkg = 'Genome::Model::ClinSeq::Command::Converge::SummarizeSnvIndelReport';
use_ok($pkg) or die;

#Define the test where expected results are stored
my $expected_output_dir = Genome::Utility::Test->data_dir_ok($pkg, '2016-05-10');

my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir") or die;

#Load the test model
my $data = Genome::Model::ClinSeq::TestData->load();
my $clinseq_build = Genome::Model::Build->get(id => $data->{CLINSEQ_BUILD});
ok($clinseq_build, "Found clinseq build.");
my $run_summarize_sireport = $pkg->create(
    outdir        => $temp_dir,
    clinseq_build => $clinseq_build,
    min_bq        => 20,
    min_mq        => 30,
);
$run_summarize_sireport->queue_status_messages(1);
$run_summarize_sireport->execute();

#Dump the output to a log file
my @output1  = $run_summarize_sireport->status_messages();
my $log_file = $temp_dir . "/summarize_sireport.log.txt";
my $log      = IO::File->new(">$log_file");
$log->print(join("\n", @output1));
$log->close();
ok(-e $log_file, "Wrote message file from generate-sciclone-plots to a log file: $log_file");

my @diff = `diff -r -x '*.log.txt' $expected_output_dir $temp_dir`;
my $ok = ok(@diff == 0, "Found only expected number of differences between expected results and test results");
unless ($ok) {
    diag("expected: $expected_output_dir\nactual: $temp_dir\n");
    diag("differences are:");
    diag(@diff);
    my $diff_line_count = scalar(@diff);
    Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-run-summarize_sireport/");
    Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-run-summarize_sireport");
    die print "\n\nFound $diff_line_count differing lines\n\n";
}

done_testing();
