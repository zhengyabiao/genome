#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;
}

use strict;
use warnings;

use above "Genome";

use Test::More;
use Genome::Utility::Test qw(compare_ok);

use_ok('Genome::ProcessingProfile::DeNovoAssembly') or die;

# Create fail - no seq platform
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'velvet one-button',
        assembler_version => '7.0.57-64',
    ),
    'Failed as expected - create w/o seq platform',
);
# Create fail - no assembler
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_version => '7.0.57-64',
    ),
    'Failed as expected - create w/o assembler',
);
# Create fail - invalid assembler
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'consed',
        assembler_version => '7.0.57-64',
    ),
    'Failed as expected - create w/ invalid assembler',
);
# Create fail - invalid coverage
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'velvet one-button',
        assembler_version => '7.0.57-64',
        coverage => -1,
    ),
    'Failed as expected - create w/ invalid coverage',
);
# Create fail - invalid assembler/platform combo
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'newbler',
        assembler_version => '7.0.57-64',
    ),
    'Failed as expected - create w/ invalid assembler and seq platform combo',
);
# Create fail - no assembler version
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'velvet one-button',
    ),
    'Failed as expected - create w/o assembler version',
);
# Create fail - invalid assembler params
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'velvet one-button',
        assembler_version => '7.0.57-64',
        assembler_params => '-wrong params',
    ),
    'Failed as expected - create w/ invalid assembler params',
);
# Create fail - calculated assembler params
ok(
    !Genome::ProcessingProfile::DeNovoAssembly->create(
        name => 'DNA Test',
        assembler_name => 'velvet one-button',
        assembler_version => '7.0.57-64',
        assembler_params => '-ins_length 260',
    ),
    'Failed as expected - create w/ calculated assembler params',
);


my $lsf_queue_alignment_default = Genome::Config::get('lsf_queue_alignment_default');
my $lsf_queue_build_worker_alt = Genome::Config::get('lsf_queue_build_worker_alt');
my @params_and_xml_list = (
    {
        params => { name => 'allpaths test pp', coverage => 50,
            read_processor => 'gmt sx trim far --nr-threads 4 --version 2.17',
            assembler_name => 'allpaths de-novo-assemble',
            assembler_version => 'allpaths test version',
        },
        workflow_xml_template => <<EOS
<?xml version="1.0"?>
<operation name="%s all stages" logDir="%s">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>build</inputproperty>
    <inputproperty>instrument_data</inputproperty>
    <outputproperty>report_directory</outputproperty>
  </operationtype>
  <operation name="Assemble">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="alignment" lsfResource="-n 4 -R 'span[hosts=1] select[mem&gt;61440] rusage[mem=61440]' -M 63963136" commandClass="Genome::Model::DeNovoAssembly::Build::Assemble" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <inputproperty>sx_results</inputproperty>
      <outputproperty>build</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <operation name="MergeAndLinkSxResults">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" lsfResource="-R 'select[gtmp&gt;1000] rusage[gtmp=1000] span[hosts=1]'" commandClass="Genome::Model::DeNovoAssembly::Build::MergeAndLinkSxResults" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>output_build</outputproperty>
      <outputproperty>result</outputproperty>
      <outputproperty>sx_results</outputproperty>
    </operationtype>
  </operation>
  <operation name="ProcessInstrumentData" parallelBy="instrument_data">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" lsfResource="-R 'select[mem&gt;32000 &amp;&amp; gtmp&gt;200] rusage[mem=32000:gtmp=200] span[hosts=1]' -M 32000000 -n 4" commandClass="Genome::Model::DeNovoAssembly::Build::ProcessInstrumentData" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <inputproperty>instrument_data</inputproperty>
      <outputproperty>build</outputproperty>
      <outputproperty>result</outputproperty>
      <outputproperty>sx_result</outputproperty>
      <outputproperty>sx_result_id</outputproperty>
    </operationtype>
  </operation>
  <operation name="Report">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" commandClass="Genome::Model::DeNovoAssembly::Command::Report" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>report_directory</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="Assemble" fromProperty="build" toOperation="Report" toProperty="build"/>
  <link fromOperation="MergeAndLinkSxResults" fromProperty="output_build" toOperation="Assemble" toProperty="build"/>
  <link fromOperation="MergeAndLinkSxResults" fromProperty="sx_results" toOperation="Assemble" toProperty="sx_results"/>
  <link fromOperation="ProcessInstrumentData" fromProperty="build" toOperation="MergeAndLinkSxResults" toProperty="build"/>
  <link fromOperation="Report" fromProperty="report_directory" toOperation="output connector" toProperty="report_directory"/>
  <link fromOperation="input connector" fromProperty="build" toOperation="ProcessInstrumentData" toProperty="build"/>
  <link fromOperation="input connector" fromProperty="instrument_data" toOperation="ProcessInstrumentData" toProperty="instrument_data"/>
</operation>
EOS
    },

    {
        params => { name => 'velvet test pp', coverage => 30,
            assembler_name => 'velvet one-button',
            assembler_version => '1.1.06',
            post_assemble => 'metrics'
        },
        workflow_xml_template => <<EOS
<?xml version="1.0"?>
<operation name="%s all stages" logDir="%s">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>build</inputproperty>
    <outputproperty>report_directory</outputproperty>
  </operationtype>
  <operation name="Assemble">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" lsfResource="-n 4 -R 'span[hosts=1] select[mem&gt;30000] rusage[mem=30000]' -M 30000000" commandClass="Genome::Model::DeNovoAssembly::Command::Assemble" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>build</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <operation name="PostAssemble">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" lsfResource="-R 'select[mem&gt;30000] rusage[mem=30000] span[hosts=1]' -M 30000000" commandClass="Genome::Model::DeNovoAssembly::Command::PostAssemble" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>build</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <operation name="PrepareInstrumentData">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" lsfResource="-R 'select[mem&gt;32000 &amp;&amp; gtmp&gt;200] rusage[mem=32000:gtmp=200] span[hosts=1]' -M 32000000" commandClass="Genome::Model::DeNovoAssembly::Build::PrepareInstrumentData" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>build</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <operation name="Report">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="apipe" commandClass="Genome::Model::DeNovoAssembly::Command::Report" lsfProject="build%s">
      <inputproperty>build</inputproperty>
      <outputproperty>report_directory</outputproperty>
      <outputproperty>result</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="Assemble" fromProperty="build" toOperation="PostAssemble" toProperty="build"/>
  <link fromOperation="PostAssemble" fromProperty="build" toOperation="Report" toProperty="build"/>
  <link fromOperation="PrepareInstrumentData" fromProperty="build" toOperation="Assemble" toProperty="build"/>
  <link fromOperation="Report" fromProperty="report_directory" toOperation="output connector" toProperty="report_directory"/>
  <link fromOperation="input connector" fromProperty="build" toOperation="PrepareInstrumentData" toProperty="build"/>
</operation>
EOS
    }

);

my $tmp_dir = File::Temp::tempdir(
    'ProcessingProfile-DeNovoAssembly-XXXXX',
    TMPDIR => 1,
    CLEANUP => 1,
);

# all this model needs to do is return something for inst data
my %inst_data_params = ( run_name => 'XXXXXX', subset_name => 1 );
my @instrument_data = (
    Genome::InstrumentData::Solexa->__define__(%inst_data_params),
    Genome::InstrumentData::Solexa->__define__(%inst_data_params));

for my $params_and_xml (@params_and_xml_list) {
    my $pp = Genome::ProcessingProfile::DeNovoAssembly->create(
        %{$params_and_xml->{'params'}});

    my $model = Genome::Model::DeNovoAssembly->__define__(
        name => "__TEST_MODEL__%s", , processing_profile => $pp,
        instrument_data => \@instrument_data);
    my $build = Genome::Model::Build::DeNovoAssembly->__define__(
        model => $model, data_directory => $tmp_dir);

    my $workflow = $pp->_resolve_workflow_for_build($build);
    $workflow->validate;

    my @operations = $workflow->operations;

    my $actual_xml = $workflow->get_xml();

    my $expected_xml = sprintf($params_and_xml->{'workflow_xml_template'},
        $build->id, $build->data_directory . '/logs/', $build->id,
        $build->id, $build->id, $build->id);

    my $expected_file = Genome::Sys->create_temp_file_path;
    my $actual_file = Genome::Sys->create_temp_file_path;

    Genome::Sys->write_file($expected_file, $expected_xml);
    Genome::Sys->write_file($actual_file, $actual_xml);
    compare_ok($expected_file, $actual_file,
        name => sprintf("workflow xml diffs for '%s'", $params_and_xml->{'params'}->{'name'}),
        replace => [
            [qr(lsfQueue="[^"]+"), q(lsfQueue="LSF_QUEUE")],
            [qr(lsfResource="[^"]+"), q(lsfResource="LSF_RESOURCE")],
        ],
    );
}

done_testing();
