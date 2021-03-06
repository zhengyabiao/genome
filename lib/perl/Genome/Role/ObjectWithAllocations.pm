package Genome::Role::ObjectWithAllocations;

use strict;
use warnings;

use Genome;
use UR::Role qw(around);

require List::MoreUtils;

role Genome::Role::ObjectWithAllocations {
    has => {
        disk_allocations => {
            is => 'Genome::Disk::Allocation',
            is_many => 1,
            reverse_as => 'owner',
        },
    },
};

my %observers_created_for_class;
around delete => sub {
    my $orig_delete = shift;
    my $self = shift;
    $self->_create_deallocate_disk_allocations_observer unless ($observers_created_for_class{$self->class}++);

    return $self->$orig_delete(@_);
};

sub _create_deallocate_disk_allocations_observer {
    my $self = shift;
    my $class = $self->class;

    my @disk_allocations = $self->disk_allocations;
    return 1 if not @disk_allocations;

    my $deallocator;
    $deallocator = sub {
        $class->_deallocate_disk_allocations(@disk_allocations);
        UR::Context->cancel_change_subscription(
            'commit', $deallocator
        );
        delete $observers_created_for_class{$class};
    };
    UR::Context->add_observer(
        aspect => 'commit',
        callback => $deallocator
    );

    return 1;
}

sub reallocate_disk_allocations {
    my ($self, %params) = @_;

    for my $disk_allocation ( $self->disk_allocations ) {
        my $reallocate_ok = eval { $disk_allocation->reallocate(%params) };
        next if $reallocate_ok;
        $self->warning_message($@) if $@;
        $self->warning_message('Continuing, but failed to reallocate disk allocation: '.$disk_allocation->__display_name__);
    }

    return 1;
}

sub deallocate_disk_allocations {
    my $self = shift;
    my $class = $self->class;
    return $class->_deallocate_disk_allocations( $self->disk_allocations );
}

sub _deallocate_disk_allocations {
    my $class = shift;

    for my $disk_allocation ( @_ ) {
        next if $disk_allocation->isa('UR::DeletedRef'); # skip if deleted
        my $deallocate_ok = eval{ $disk_allocation->deallocate; };
        next if $deallocate_ok;
        $class->warning_message($@) if $@;
        $class->warning_message('Continuing, but failed to deallocate disk allocation: '.$disk_allocation->__display_name__);
    }

    return 1;
}

sub are_disk_allocations_archivable {
    my $self = shift;

    my @disk_allocations = $self->disk_allocations;
    return 0 unless @disk_allocations;

    return List::MoreUtils::all { $_->archivable } @disk_allocations;
}

sub are_disk_allocations_archived {
    my $self = shift;
    return List::MoreUtils::any { $_->is_archived } $self->associated_disk_allocations;
}

sub associated_disk_allocations {
    my $self = shift;

    return List::MoreUtils::uniq(
        $self->disk_allocations,
        $self->_additional_associated_disk_allocations,
    );
}
sub _additional_associated_disk_allocations { return (); }

sub unarchive_disk_allocations {
    my ($self, %params) = @_;
    return $self->_unarchive_disk_allocations(%params);
}

sub _unarchive_disk_allocations { # default is to iterrate over allocation and unarchive them
    my ($self, %params) = @_;

    for my $disk_allocation ( $self->disk_allocations ) {
        next if not $disk_allocation->is_archived;
        my $unarchive_ok = eval{ $disk_allocation->unarchive(%params); };
        next if $unarchive_ok;
        $self->error_message($@) if $@;
        $self->error_message('Failed to unarchive disk allocation! '.$disk_allocation->__display_name__);
        return;
    }

    return 1;
}

1;

