package Genome::Model::RnaSeq::Command::ErccSpikeInQc;

use strict;
use warnings;

use Genome;
use Cwd;

class Genome::Model::RnaSeq::Command::ErccSpikeInQc {
    is => 'Command::V2',
    has_input => [
        models => {
            is => 'Genome::Model::RnaSeq',
            is_many => 1,
            doc => 'RNA-seq models to evaluate ERCC spike-in.',
            shell_args_position => 1,
        },
        ercc_spike_in_mix => {
            is => 'Integer',
            doc => 'The expected ERCC spike-in mix.',
            valid_values => [ '1', '2'],
        },
        ercc_spike_in_file => {
            is => 'Text',
            doc => 'The control analysis file provided by Agilent for the ERCC spike-in.',
            example_values => ['/gscmnt/gc13001/info/model_data/jwalker_scratch/ERCC/ERCC_Controls_Analysis.txt'],
        },
        output_directory => {
            is => 'Text',
            doc => 'The output directory to write summary file and PDF plots, one per model ID sub-directory.',
        },
    ],
    doc => 'generate ERCC spike-in QC metrics on RNA-seq BAM results'
};

sub help_detail {
    return <<EOS
Compare the abundance of an ERCC spike-in with a known concentration.
EOS
}

sub execute {
    my $self = shift;

    my $ercc_hash_ref = $self->_load_ercc_hash_ref;
    
    for my $model ($self->models) {
        my $build = $model->latest_build;
        my $fpkm_hash_ref = $self->_load_fpkm_hash_ref($build);
        my $count_hash_ref = $self->_load_count_hash_ref($build);

        my $r_tsv_file = $self->_write_temp_file($ercc_hash_ref,$fpkm_hash_ref,$count_hash_ref);
        $self->_generate_r_plots($r_tsv_file,$model);
    }
    
    return 1;
}

sub _write_temp_file {
    my $self = shift;
    
    my $ercc_hash_ref = shift;
    my $fpkm_hash_ref = shift;
    my $count_hash_ref = shift;
    
    # TODO: resolve the mix from the build or input instrument data once LIMS library attribute exists
    my $mix = $self->ercc_spike_in_mix;
    
    my $ercc_file_path = Genome::Sys->create_temp_file_path();
    my @output_headers = ('Re-sort ID','ERCC ID','subgroup','ERCC Mix','concentration (attomoles/ul)','FPKM','FPKM_conf_lo','FPKM_conf_hi','count');
    my $writer = Genome::Utility::IO::SeparatedValueWriter->create(
        output => $ercc_file_path,
        separator => "\t",
        headers => \@output_headers,
    );

    my %ercc_data = %{$ercc_hash_ref};
    my %fpkm_data = %{$fpkm_hash_ref};
    my %count_data = %{$count_hash_ref};

    my $concentration_key = 'concentration in Mix '. $mix .' (attomoles/ul)'
    for my $gene_id (sort { $ercc_data{$a}->{'Re-sort ID'} <=> $ercc_data{$b}->{'Re-sort ID'}} keys %ercc_data   ) {
        my %data = (
            'Re-sort ID' => $ercc_data->{'Re-sort ID'},
            'ERCC ID' => $ercc_data->{'ERCC ID'},
            'subgroup' => $ercc_data->{'subgroup'},
            'ERCC Mix' => $mix,
            'concentration (attomoles/ul)' => $ercc_data{$gene_id}{$concentration_key},
            'FPKM' => $fpkm_data{$gene_id}{'FPKM'},
            'FPKM_conf_lo' => $fpkm_data{$gene_id}{'FPKM_conf_lo'},
            'FPKM_conf_hi' => $fpkm_data{$gene_id}{'FPKM_conf_hi'},
            'count' => $count_data{$gene_id},
        );
        $writer->write_one(\%data);
    }
    $writer->output->close;
    return $ercc_file_path;
}

sub _load_ercc_hash_ref {
    my $self = shift;
    my $ercc_spike_in_file = $self->ercc_spike_in_file;
    my $reader = Genome::Utility::IO::SeparatedValueReader->create(
        input => $ercc_spike_in_file,
        separator => "\t",
    );
    unless ($reader) {
        die($self->error_message('Failed to load ERCC control file: '. $ercc_spike_in_file));
    }
    my %ercc_data;
    while (my $data = $reader->next) {
        $ercc_data{$data->{'ERCC ID'}} = $data;
    }
    $reader->input->close;
    return \%ercc_data;
}

sub _load_fpkm_hash_ref {
    my $self = shift;
    my $build = shift;
    
    # Cufflinks FPKM values
    my $genes_fpkm_file = $build->data_directory.'/expression/genes.fpkm_tracking';
    my $genes_fpkm_reader = Genome::Utility::IO::SeparatedValueReader->create(
        input => $genes_fpkm_file,
        separator => "\t",
    );
    unless ($genes_fpkm_reader) {
        die( $self->error_message('Failed to load Cufflinks FPKM file: '. $genes_fpkm_file) );
    }
    my %fpkm_data;
    while ( my $genes_fpkm_data = $genes_fpkm_reader->next ) {
        if ( $genes_fpkm_data->{'gene_id'} =~ /^ERCC-\d{5}$/ ) {
            $fpkm_data{$genes_fpkm_data->{'gene_id'}}{'FPKM'} = $genes_fpkm_data->{'FPKM'};
            $fpkm_data{$genes_fpkm_data->{'gene_id'}}{'FPKM_conf_lo'} = $genes_fpkm_data->{'FPKM_conf_lo'};
            $fpkm_data{$genes_fpkm_data->{'gene_id'}}{'FPKM_conf_hi'} = $genes_fpkm_data->{'FPKM_conf_hi'};
        }
    }
    $genes_fpkm_reader->input->close;
    return \%fpkm_data;
}

sub _load_count_hash_ref {
    my $self = shift;
    my $build = shift;
    
    # HTSeq count values
    my $genes_count_file = $build->data_directory .'/results/digital_expression_result/gene-counts.tsv';
    my @count_headers = qw/gene_id count/;
    my $genes_count_reader = Genome::Utility::IO::SeparatedValueReader->create(
        input => $genes_count_file,
        separator => "\t",
        headers => \@count_headers,
    );
    unless ($genes_count_reader) {
        die( $self->error_message('Failed to load htseq-count file: '. $genes_count_file) );
    }

    my %count_data;
    while ( my $genes_count_data = $genes_count_reader->next ) {
        if ( $genes_count_data->{'gene_id'} =~ /^ERCC-\d{5}$/ ) {
            $count_data{$genes_count_data->{'gene_id'}} = $genes_count_data->{'count'};
        }
    }
    $genes_count_reader->input->close;

    return \%count_data;
}

sub _generate_r_plots {
    my $self = shift;
    my $summary_file = shift;
    my $model = shift;
    
    my $r_script_path = $self->__meta__->module_path;
    $r_script_path =~ s/\.pm/\.R/;

    my $cwd = getcwd();

    my $cmd = 'Rscript '. $r_script_path .' --filename '. $summary_file;

    my $output_directory = $self->output_directory .'/'. $model->id;
    unless (-d $output_directory ) {
        Genome::Sys->create_directory($output_directory);
    }
    chdir($output_directory);
    Genome::Sys->shellcmd(
        cmd => $cmd,
    );
    chdir($cwd);
    
    return 1;
}




1;
