#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::Exception;
use Test::More;
use Genome::File::Vcf::Entry;

my $pkg = "Genome::VariantReporting::Vep::VepInterpreter";
use_ok($pkg);
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('interpreters', $pkg->name), $pkg);

subtest "one alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            transcript_name   => 'ENST00000452176',
            trv_type          => 'downstream_gene_variant',
            trv_type_category => 'other',
            amino_acid_change => '',
            default_gene_name => 'RP5-857K21.5',
            ensembl_gene_id   => 'ENSG00000223659',
            gene_name_source => 'Clone_based_vega_gene',
            c_position => '',
            sift => '',
            polyphen => '',
            condel => '',
            canonical => 1,
        }
    );
    my $entry = create_entry();
    is_deeply({$interpreter->interpret_entry($entry, ['C'])}, \%expected_return_values, "Entry gets interpreted correctly");
};


subtest "two alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            transcript_name   => 'ENST00000452176',
            trv_type          => 'downstream_gene_variant',
            trv_type_category => 'other',
            amino_acid_change => '',
            default_gene_name => 'RP5-857K21.5',
            ensembl_gene_id   => 'ENSG00000223659',
            gene_name_source => 'Clone_based_vega_gene',
            c_position => '',
            sift => '',
            polyphen => '',
            condel => '',
            canonical => 1,
        },
        G => {
            transcript_name   => 'ENST00000452176',
            trv_type          => 'downstream_gene_variant',
            trv_type_category => 'other',
            amino_acid_change => '',
            default_gene_name => 'RP5-857K22.5',
            ensembl_gene_id   => 'ENSG00000223695',
            gene_name_source => 'Clone_based_vega_gene',
            c_position => 'example_hgvsc',
            sift => 'example_sift',
            polyphen => 'example_polyphen',
            condel => 'example_condel',
            canonical => 1,
        },
    );
    my $entry = create_entry();
    is_deeply({$interpreter->interpret_entry($entry, ['C', 'G'])}, \%expected_return_values, "Entry gets interpreted correctly");
};

subtest 'is_splice_site' => sub {
    ok(
        Genome::VariantReporting::Vep::VepInterpreter::is_splice_site(Set::Scalar->new('splice_acceptor_variant')),
        "('splice_acceptor_variant') is splice site"
    );
    ok(
        Genome::VariantReporting::Vep::VepInterpreter::is_splice_site(Set::Scalar->new('splice_acceptor_variant', 'not_splice_site')),
        "('splice_acceptor_variant', 'not_splice_site') is splice site"
    );
    ok(
        !Genome::VariantReporting::Vep::VepInterpreter::is_splice_site(Set::Scalar->new('not_splice_site')),
        "('not_splice_site') is not splice site"
    );
};

subtest 'is_non_synonymous' => sub {
    ok(
        Genome::VariantReporting::Vep::VepInterpreter::is_non_synonymous(Set::Scalar->new('transcript_ablation')),
        "('transcript_ablation') is non synonymous"
    );
    ok(
        Genome::VariantReporting::Vep::VepInterpreter::is_non_synonymous(Set::Scalar->new('transcript_ablation', 'not_non_synonymous')),
        "('transcript_ablation', 'not_non_synonymous') is non synonymous"
    );
    ok(
        !Genome::VariantReporting::Vep::VepInterpreter::is_non_synonymous(Set::Scalar->new('not_non_synonymous')),
        "('not_non_synonymous') is not non synonymous"
    );
};

subtest 'trv_type_category' => sub {
    is(
        Genome::VariantReporting::Vep::VepInterpreter::trv_type_category('splice_acceptor_variant'),
        'splice_site',
        'trv type category as expected'
    );
    is(
        Genome::VariantReporting::Vep::VepInterpreter::trv_type_category('transcript_ablation'),
        'non_synonymous',
        'trv type category as expected'
    );
    is(
        Genome::VariantReporting::Vep::VepInterpreter::trv_type_category('splice_acceptor_variant&transcript_ablation'),
        'splice_site',
        'trv type category as expected'
    );
    is(
        Genome::VariantReporting::Vep::VepInterpreter::trv_type_category('no_splice_site'),
        'other',
        'trv type category as expected'
    );
};

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=CSQ,Number=.,Type=String,Description="Consequence type as predicted by VEP. Format: Allele|Gene|Feature|Feature_type|Consequence|cDNA_position|CDS_position|Protein_position|Amino_acids|Codons|Existing_variation|DISTANCE|CANONICAL|SYMBOL|SYMBOL_SOURCE|SIFT|PolyPhen|HGVSc|HGVSp|Condel">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
##FORMAT=<ID=FT,Number=.,Type=String,Description="Filter">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	S1	S2	S3	S4
EOS
    my @lines = split("\n", $header_txt);
    my $header = Genome::File::Vcf::Header->create(lines => \@lines);
    return $header
}

sub create_entry {
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        'A',            # REF
        'C,G',            # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
        'CSQ=C|ENSG00000223659|ENST00000452176|Transcript|downstream_gene_variant|||||||4680|YES|RP5-857K21.5|Clone_based_vega_gene|||||,G|ENSG00000223695|ENST00000452176|Transcript|downstream_gene_variant|||||||4680|YES|RP5-857K22.5|Clone_based_vega_gene|example_sift|example_polyphen|example_hgvsc||example_condel',  # INFO
        'GT:DP',     # FORMAT
        "0/1:12",   # FIRST_SAMPLE
    );

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}

done_testing;
