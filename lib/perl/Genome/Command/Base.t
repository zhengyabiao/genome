#!/usr/bin/env genome-perl
use strict;
use warnings;

BEGIN {
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;
};

use above "Genome";
use Test::More tests => 9;
my $v;

class Genome::ProcessingProfile::Foo { is => 'Genome::ProcessingProfile' };

my $p = Genome::ProcessingProfile::Foo->create(name => "profile1");
ok($p, 'made a profile');

my $s = Genome::Sample->create(name => 'sample1');
ok($s, 'made a sample');

my @p = (processing_profile => $p, subject_class_name => ref($s), subject_id => $s);

my $m1 = Genome::Model::Foo->create(@p, name => 'model1');
ok($m1, "made a model $m1");
my $m2 = Genome::Model::Foo->create(@p, name => 'model2');
ok($m1, "made a model $m2");
my $m3 = Genome::Model::Foo->create(@p, name => 'model3');
ok($m1, "made a model $m3");

class Genome::Model::Command::T1 {
    is => 'Command::V2',
    has => [
        model => { is => 'Genome::Model' },
    ]
};
Genome::Model::Command::T1->dump_status_messages(0);
Genome::Model::Command::T1->dump_error_messages(0);
Genome::Model::Command::T1->queue_status_messages(1);
Genome::Model::Command::T1->queue_error_messages(1);
sub Genome::Model::Command::T1::execute {
    my $self = shift;
    $v = $self->model;
    #print ">>$v<<\n";
    return 1;
}

sh("genome model t1 --model model1");
is($v, $m1, "got single model with full name");
my @status_messages = Genome::Model::Command::T1->status_messages();
is_deeply(\@status_messages,
    [   q('model' may require verification...),
        q(Resolving parameter 'model' from command argument 'model1'... found 1) ],
    'Expected status messages');
my @error_messages = Genome::Model::Command::T1->error_messages();
is(scalar(@error_messages), 0, 'No error messages');

sub sh {
    my $txt = shift;
    my @w = split(/\s+/,$txt);
    shift @w;
    my $e = Genome::Command->_execute_with_shell_params_and_return_exit_code(@w);
    die if $e;
}

{
    local *STDERR;
    open(STDERR,">/dev/null") or die "Failed to redirect STDERR";
    my $rv = eval {
        Command::V2->_ask_user_question('Can I talk to you?');
    };
}
ok($@ =~ /Attempting to ask user question but cannot interact with user!/, "correctly died when unable to interact with user");

__END__
my $e = Genome::Command->_execute_with_shell_params_and_return_exit_code(
    'model t1  
);
