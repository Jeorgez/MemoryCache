package MemoryCache::ClientManager;

use strict;
use AnyEvent::HTTPD;
use MemoryCache::StorageDriver;
use MemoryCache::Tools qw/smart_new cdie/;
use MemoryCache::Cookie;
use MemoryCache::Client;
use Data::Dumper;

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

my @_clients = ();

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub new {
    my $self = {};
    bless $self, __PACKAGE__;
    return $self;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub get_client {
    my $self = shift;
    my ($http_request) = @_;
    my $session_id;
    my $client;
    
    my $cookie = new MemoryCache::Cookie( http_request => $http_request );
    if ($cookie->get("session_id")) {
        $session_id = $cookie->get("session_id");
        $client     = $self->find_client($session_id);
    }
    unless ( $session_id && defined $client ) {
        $session_id = MemoryCache::Tools::gen_random_string(32);
        $client     = $self->create_client($session_id);
    }
    
    return $client;
}

sub find_client {
    my $self        = shift;
    my $session_id  = shift;    
    foreach my $client (@_clients){
        if($client->get_session_id eq $session_id){
            return $client;
        }
    }
    return undef;
}

sub create_client {
    my $self        = shift;
    my $session_id  = shift;
    my $client = new MemoryCache::Client (
        session_id      => $session_id
    );
    push @_clients, $client;
    return $client;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

1;