#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

my $pkg = 'Genome::Site::TGI::CleTest';
use_ok($pkg);

my $config = Genome::Site::TGI::CleTest::get_config();
my $expected_config = {
    'blessed_process' => '2b2b3d8481284fcf8a1632d65ba58083',
    'blessed_builds' => [
    '185d8bac3d7c4437b7ce9207dfadac7e',
    '5f57f08a8fd84886b275f0b5571e9fd7',
    'e02e8a5ccaad458d839de51eb47d8d2c',
    '26e65adaa8034dd99ef92b27f61ad862',
    '3243f261a8b64c089a5254291f7c2de3',
    'f87701c292e843958d088e171a65a67a',
    '301d5d51c96e41308d015008720f3962'
    ],
    'tag_to_menu_item' => {
        'germline' => '3770b8510d5a459f9c0bb01fabf56337',
        'followup' => '9ab6e28f832a428393b87b171d444401',
        'discovery' => '9ab6e28f832a428393b87b171d444401'
    },
    'instrument_data' => [
    '2893814999',
    '2893815000',
    '2893815001',
    '2893815002',
    '2893815003',
    '2893815016',
    '2893815018',
    '2893815020',
    '2893815023',
    '2893815024',
    '2893815447',
    '2893815448',
    '2893815449',
    '2893815451',
    '2893815484',
    '2893815485',
    '2893815489',
    '2893815492'
    ],
    'region_of_interest_set_name' => 'SeqCap EZ Human Exome v3.0 + AML RMG pooled probes + WO2830729 pooled probes + WO2840081 pooled probes',
    'subject_mapping_string' => "H_KA-174556-1309237\tH_KA-174556-1309246\t\t\t\tfollowup\nH_KA-174556-1309245\tH_KA-174556-1309246\t\t\t\tdiscovery\nH_KA-174556-1309246\t\t\t\t\tgermline\n"
};
is_deeply($config, $expected_config, "Config read in correctly");

done_testing;
