package MemoryCache::Client;

use strict;
use AnyEvent::Tools qw(mutex);
use MemoryCache::StorageDriver;
use MemoryCache::Tools qw/cdie p_error/;
use MemoryCache::Client::Request;
use Data::Dumper;

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

my $_add_request = sub {
    my $self            = shift;
    my %args            = @_;
    my $http_request    = $args{http_request};
    # Create new client request
    my $client_request  = new MemoryCache::Client::Request(
        http_request        => $http_request,
        client              => $self
    );
    if($client_request) {
        my $cv = AE::cv;
        # Lock mutex and set callback
        $self->{requests_mutex}->lock(sub {
            my $g = shift;
            push (@{$self->{requests}}, $client_request);
            $cv->send( $self->{processing} );
            # Unlock mutex
            undef $g; 
        });
        # Waiting for callback and receive value.
        my ($processing) = $cv->recv;
        return $processing;
    } else {
        p_error ("HTTP request isn't correct.");
    }
    return undef;
};

my $_shift_request = sub {
    my $self = shift;
    my $request;
    my $cv = AE::cv;
    # Lock mutex and set callback
    $self->{requests_mutex}->lock(sub {
        my $g = shift;
        # If array isn't empty then get first request
        if (@{$self->{requests}}) {
            $request = shift @{$self->{requests}};
            $self->{processing} = 1;
        } else {
            $self->{processing} = 0;
        }
        $cv->send;
        undef $g; # unlock mutex
    });
    # Waiting for callback
    $cv->recv;
    return $request;
};

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub new {
    my $class   = shift;
    $class      = ref $class || $class;
    my %args            = @_;
    my $session_id      = $args{session_id}     || cdie ("Session isn't defined.");
    my $storage_driver;
    if ($args{storage_driver} && ref $args{storage_driver} eq "MemoryCache::StorageDriver") {
        $storage_driver  = $args{storage_driver};
    } else {
        $storage_driver  = new MemoryCache::StorageDriver();
    }
    my $http_request    = $args{http_request};
    my $self = {
        session_id          => $session_id,
        storage_driver      => $storage_driver,
        requests            => [],
        requests_mutex      => mutex,
        processing          => 0,
    };
    bless $self, $class;
    if ($http_request) {
        $self->$_add_request( http_request => $http_request );
    }
    
    return $self;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub get_session_id {
    my $self = shift;
    return $self->{session_id};
}

sub get_storage_driver {
    my $self = shift;
    return $self->{storage_driver};
}

sub add_request {
    my $self            = shift;
    my $http_request    = shift;
    if($http_request && ref $http_request eq "AnyEvent::HTTPD::Request"){
        return $self->$_add_request( http_request => $http_request );
    }
    return undef;
}

sub get_request {
    my $self = shift;
    return $self->$_shift_request();
}
# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

1;