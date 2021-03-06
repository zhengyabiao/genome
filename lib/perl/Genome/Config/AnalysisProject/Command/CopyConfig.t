#!/usr/bin/env genome-perl

use strict;
use warnings;

use feature qw(state);

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use Test::More tests => 5;
use above 'Genome';

my $class = 'Genome::Config::AnalysisProject::Command::CopyConfig';

use_ok($class);

my $existing_config_file = Genome::Sys->create_temp_file_path();
my $existing_config_contents = 'existing config!';
Genome::Sys->write_file($existing_config_file, $existing_config_contents);

my $menu_item_file = Genome::Sys->create_temp_file_path();
my $menu_item_contents = 'menu item';
Genome::Sys->write_file($menu_item_file, $menu_item_contents);

my $test_menu_item = Genome::Config::AnalysisMenu::Item->create(
    name => 'Test Menu Item',
    file_path => $menu_item_file,
);

my $source_project = Genome::Config::AnalysisProject->create(
    name => 'Test Source Project',
);

Genome::Config::Profile::Item->create(
    analysis_menu_item => $test_menu_item,
    analysis_project => $source_project,
);

my $item = Genome::Config::Profile::Item->create_from_file_path(
    file_path => $existing_config_file,
    analysis_project => $source_project,
);

subtest 'no tag flag and no tags' => sub { _run_command($source_project, 0, 0); };
subtest 'tag flag but no tags'    => sub { _run_command($source_project, 1, 0); };

Genome::Config::Tag::Profile::Item->create(
    profile_item => $item,
    tag => Genome::Config::Tag->create(name => 'test tag for CopyConfig.t'),
);

subtest 'tag but no tag flag' => sub { _run_command($source_project, 0, 0); };
subtest 'tag and tag flag'    => sub { _run_command($source_project, 1, 1); };


sub _run_command {
    state $count = 0;

    my ($source_project, $use_tag_flag, $expected_tag_count) = @_;

    my $target_project = Genome::Config::AnalysisProject->create(
        name => 'Test Target Project ' . $count++,
    );

    my $cmd = $class->create(
        to_project => $target_project,
        from_project => $source_project,
        tags => $use_tag_flag,
    );
    ok($cmd->execute(), 'command executed successfully');

    my @newly_created_profile_items = $target_project->config_items;
    is(scalar(@newly_created_profile_items), 2, 'it should copy over both types of config profile items');
    is((grep { $_->is_concrete } @newly_created_profile_items), 1,
        'one of the items should be concrete');
    is((grep { $_->analysis_menu_item } @newly_created_profile_items), 1,
        'one of the items should be an analysis menu item');

    is((grep { $_->tags } @newly_created_profile_items), $expected_tag_count,
        'Found expected number of tags set');
}
