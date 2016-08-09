#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above 'Genome';
use Test::More;
use File::Spec;

Genome::Report::Email->silent();

if (Genome::Sys->arch_os ne 'x86_64') {
    plan skip_all => 'requires 64-bit machine';
} else {
    plan tests => 8;
}

my $cmd_class = 'Genome::Model::Command::Define::ImportedReferenceSequence';
use_ok($cmd_class);

my $data_dir = Genome::Sys->create_temp_directory();

my $pp = Genome::ProcessingProfile::ImportedReferenceSequence->create(name => 'test_rederivable_ref_pp');
my $taxon = Genome::Taxon->get(name => 'human');

my $fasta_file = File::Spec->join($data_dir, 'test.fa');
Genome::Sys->write_file($fasta_file,">TEST_1\nNANANANANA\n");

my %params = (
    fasta_file => $fasta_file,
    model_name => 'test-rederivable-ref-seq-1',
    processing_profile_id => $pp->id,
    species_name => 'human',
    version => '-42',
    use_default_sequence_uri => 1,
    is_rederivable => 1,
);

my $cmd = $cmd_class->create(%params);
isa_ok($cmd, $cmd_class, 'created command');
ok($cmd->execute, 'executed command');

my $refseq = Genome::Model::Build->get($cmd->result_build_id);
ok($refseq, 'got a build');
ok($refseq->fasta_md5, 'reference has an MD5 set');

$params{version} = '-42.1';

my $repeat_cmd = $cmd_class->create(%params);
isa_ok($repeat_cmd, $cmd_class, 'created a repeat command');
ok($repeat_cmd->execute, 'executed a repeat command');

is($repeat_cmd->result_build_id, $refseq->id, 'found same reference instead of creating a new one');
