package MemoryCache::StorageDriver::StorageMod;

use strict;
use MemoryCache::Tools qw/cdie/;
use MemoryCache::StorageDriver::Static;
use AnyEvent;
use AnyEvent::Tools qw(mutex);
use Coro;

my %_data = ();

my $_d = sub {
    my $self        = shift;
    my %args        = @_;
    $_data{$self}   = {} unless exists $_data{$self};
    if (%args) {
        foreach my $k (keys %args) {
            $_data{$self}->{$k} = $args{$k};
        }
    }
    return $_data{$self};
};

my $_delete_d = sub {
    my $self = shift;
    delete $_data{$self} if exists $_data{$self};
};

my $_add_task = sub {
    my $self    = shift;
    my %args    = @_;
    my $task    = {};
    foreach my $k (qw/driver method method_args callback/){
        $task->{$k} = $args{$k} if $args{$k};
    }
    my $cv = AE::cv;
    $self->$_d->{queue_lock}->lock(sub {
        my ($guard) = @_;
        push @{$self->$_d->{queue}}, $task;
        undef $guard; # unlock mutex
        $cv->send(1);
    });
    my @ips = $cv->recv;
    return 1;
};

my $_get_task = sub {
    my $self = shift;
    my $cv = AE::cv;
    $self->$_d->{queue_lock}->lock(sub {
        my ($guard) = @_;
        my $task;
        if(@{$self->$_d->{queue}}){
            $task = shift @{$self->$_d->{queue}};
        }
        undef $guard; # unlock mutex
        $cv->send( task => $task);
    });
    my %result = $cv->recv;
    return $result{task};
};

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my $self = {};
    bless $self, $class;
    $self->$_d(
        queue           => [],
        queue_lock      => mutex,
        handler_timer   => undef,
        expires_timer   => undef
    );
    if($class ne STORAGE_CLEAN->{p}){
        $self->_delete_expired() || cdie("Method to clear expires data - _delete_expired isn't defined in your module.");
    }
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->stop_handler();
    $self->$_delete_d;
}

sub add_task {
    my $self        = shift;
    my %args        = @_;
    return $self->$_add_task(%args);
}

sub run_handler {
    my $self = shift;
    return if $self->$_d->{handler_timer};
    $self->$_d->{handler_timer} = AnyEvent->timer(
        after       => 0,
        interval    => 0.0001,
        cb          => sub {
            if ( @{$self->$_d->{queue}} ) {
                my $task = $self->$_get_task();
                my @args;
                @args = @{$task->{method_args}} if ref $task->{method_args} eq "ARRAY";
                @args = %{$task->{method_args}} if ref $task->{method_args} eq "HASH";
                my @result = &{$task->{method}}($self, @args);
                async {
                    &{$task->{callback}}(@result);
                }
            }
        }
    );
    $self->$_d->{expires_timer} = AnyEvent->timer(
        after       => 0,
        interval    => 5,
        cb          => sub {
            $self->_delete_expired();
        }
    );
}

sub stop_handler {
    my $self = shift;
    delete $self->$_d->{handler_timer};
    delete $self->$_d->{expires_timer};
}

sub get_handler_status {
    my $self = shift;
    return defined $self->$_d->{handler_timer};
}

sub _delete_expired { undef; }

sub get     { undef; }

sub set     { undef; }

sub delete  { undef; }

sub list    { undef; }

1;