package Genome::Model::Tools::454::Newbler;

use strict;
use warnings;

use Genome;

use XML::Simple;
use File::Basename;

class Genome::Model::Tools::454::Newbler {
    is => ['Genome::Model::Tools::454'],
};

sub sub_command_sort_position { 12 }

sub help_brief {
    "Tools to run newbler or work with its output files.",
}

sub help_synopsis {
    my $self = shift;
    return <<"EOS"
genome-model tools newbler ...
EOS
}

sub help_detail {
    return <<EOS
EOS
}

sub newbler_bin {
    my $self = shift;

    my $bin_path = $self->bin_path;

    return $bin_path;
}

sub full_bin_path {
    my $self = shift;
    my $cmd = shift;

    return $self->newbler_bin .'/'. $cmd;
}

sub get_newbler_version_from_xml_file {
    my $class = shift;
    my $xml_file = shift;

    if (ref($class)) {
        $class = ref($class);
    }
    my $xml = XML::Simple->new( Forcearray => [ qw( book ) ], keyattr => { book => 'isbn' } );
    my $xml_data = $xml->XMLin($xml_file);
    return unless exists $xml_data->{ProjectInformation}->{SoftwareVersion};
    return $xml_data->{ProjectInformation}->{SoftwareVersion};
}


1;

