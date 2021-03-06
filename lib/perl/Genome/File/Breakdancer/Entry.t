#!/usr/bin/env perl

use above 'Genome';
use Data::Dumper;
use Test::More;
use Genome::File::Breakdancer::Header;
use Genome::File::Breakdancer::Reader;

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

my $pkg = "Genome::File::Breakdancer::Entry";

use_ok($pkg);

my $header_txt = "";
my @lines = split("\n", $header_txt);
my $header = new Genome::File::Breakdancer::Header(lines => \@lines);

subtest "parse basic entry" => sub {
    my @fields = (
        '1',                # chr1
        10,                 # pos1
        '10+9-',            # orientation1
        '1',                # chr2
        100,                # pos2
        '11+8-',            # orientation2
        'DEL',              # type
        90,                 # size
        88,                 # score
        16,                 # num_reads
        'lib1|7,1:lib2|9,NA',    # num_reads_lib
    );

    my $entry_txt = join("\t", @fields);
    my $entry = $pkg->new($header, $entry_txt);
    is($entry->{chr1}, 1, 'chr1');
    is($entry->{pos1}, 10, 'pos1');
    is($entry->{orientation1}{fwd}, 10, "orientation1 (fwd)");
    is($entry->{orientation1}{rev}, 9, "orientation1 (rev)");
    is($entry->{chr2}, 1, 'chr2');
    is($entry->{pos2}, 100, 'pos2');
    is($entry->{orientation2}{fwd}, 11, "orientation1 (fwd)");
    is($entry->{orientation2}{rev}, 8, "orientation1 (rev)");
    is($entry->{type}, "DEL", "type");
    is($entry->{size}, 90, "size");
    is($entry->{score}, 88, "score");
    is($entry->{num_reads}, 16, "num_reads");
    is($entry->{num_reads_lib}{lib1}{count}, 7, "num_reads_lib (lib1)");
    is($entry->lib_read_count("lib1"), 7, "lib_read_count(lib1)");
    is($entry->{num_reads_lib}{lib2}{count}, 9, "num_reads_lib (lib2)");
    is($entry->lib_read_count("lib2"), 9, "lib_read_count(lib2)");
    is($entry->{num_reads_lib}{lib1}{copy_number}, 1, "copy number (lib1)");
    is($entry->{num_reads_lib}{lib2}{copy_number}, "NA", "copy number (lib2)");
    is_deeply($entry->{extra}, [], "extra");
    is($entry->to_string, join("\t", @fields), "to_string");
};

# Squaredancer frequently reports orientation as 10+ rather than 10+0-
# The parsing code was expecting both to always be reported
subtest "parse squaredancer entry" => sub {

    my @fields = (
        '1',                # chr1
        10,                 # pos1
        '10+',              # orientation1
        '1',                # chr2
        100,                # pos2
        '8-',               # orientation2
        'DEL',              # type
        90,                 # size
        88,                 # score
        16,                 # num_reads
        'lib1|7,1:lib2|9,NA',    # num_reads_lib
    );

    my @expected_fields = @fields;
    $expected_fields[2] = sprintf("%s0-", $expected_fields[2]);
    $expected_fields[5] = sprintf("0+%s", $expected_fields[5]);

    my $entry_txt = join("\t", @fields);

    my $entry = $pkg->new($header, $entry_txt);
    is($entry->{chr1}, 1, 'chr1');
    is($entry->{pos1}, 10, 'pos1');
    is($entry->{orientation1}{fwd}, 10, "orientation1 (fwd)");
    is($entry->{orientation1}{rev}, 0, "orientation1 (rev)");
    is($entry->{chr2}, 1, 'chr2');
    is($entry->{pos2}, 100, 'pos2');
    is($entry->{orientation2}{fwd}, 0, "orientation1 (fwd)");
    is($entry->{orientation2}{rev}, 8, "orientation1 (rev)");
    is($entry->{type}, "DEL", "type");
    is($entry->{size}, 90, "size");
    is($entry->{score}, 88, "score");
    is($entry->{num_reads}, 16, "num_reads");
    is($entry->{num_reads_lib}{lib1}{count}, 7, "num_reads_lib (lib1)");
    is($entry->lib_read_count("lib1"), 7, "lib_read_count(lib1)");
    is($entry->{num_reads_lib}{lib2}{count}, 9, "num_reads_lib (lib2)");
    is($entry->lib_read_count("lib2"), 9, "lib_read_count(lib2)");
    is($entry->{num_reads_lib}{lib1}{copy_number}, 1, "copy number (lib1)");
    is($entry->{num_reads_lib}{lib2}{copy_number}, "NA", "copy number (lib2)");
    is_deeply($entry->{extra}, [], "extra");

    is($entry->to_string, join("\t", @expected_fields), "to_string");
};


done_testing();
