#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Genome::File::Vcf::Entry;
use Test::More;
use Test::Exception;

my $pkg = "Genome::VariantReporting::Generic::IndelSizeInterpreter";
use_ok($pkg) or die;
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('interpreters', $pkg->name), $pkg);


my $interpreter = $pkg->create();
lives_ok(sub {$interpreter->validate}, "Filter validates ok");

my $entry = create_entry('A', 'AAAAA,AAAAAA');
ok($entry, 'create entry');

subtest 'test wrong input alleles' => sub {
    for my $allele (qw(BBBBBB GGGGGG --__++)) {
        my $rv = eval {$interpreter->interpret_entry($entry, [$allele])};
        ok(!$rv, 'Failed as expected: '.$@);
    }
};

subtest 'all alt alleles' => sub {
    my %expected_return_values = (
        AAAAA => { indel_size => 4 },
        AAAAAA => { indel_size => 5 },
    );
    is_deeply({$interpreter->interpret_entry($entry, ['AAAAA', 'AAAAAA'])}, \%expected_return_values, "return values");
};

subtest 'single alt alleles only' => sub {
    my %expected_return_values = (
        AAAAA => { indel_size => 4 },
    );
    is_deeply({$interpreter->interpret_entry($entry, ['AAAAA'])}, \%expected_return_values, "return values");
};

done_testing;

###

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=A,Number=1,Type=String,Description="Info field A">
##INFO=<ID=C,Number=A,Type=String,Description="Info field C (per-alt)">
##INFO=<ID=E,Number=0,Type=Flag,Description="Info field E">
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
    my ($ref, $alt) = @_;
    die "Missing REF or ALT!" if not @_ == 2;
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        $ref,            # REF
        $alt,           # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
        'A=B;C=8,9;E',  # INFO
        'GT:DP',        # FORMAT
    );

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}

