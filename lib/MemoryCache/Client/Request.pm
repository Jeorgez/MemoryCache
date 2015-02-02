package MemoryCache::Client::Request;

use strict;
use MemoryCache::Cookie;
use MemoryCache::Tools qw/cdie/;
use Data::Dumper;

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

my %_header = (
    "Access-Control-Allow-Origin"   => "*",
    "Content-Type"                  => "text/html"
);

my $_get_set_cookie = sub {
    my $self    = shift;
    my %result  = ();
    %result     = %{$self->{cookie}->_set_cookie()} if ($self->{cookie});
    return %result;
};

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub new {
    my $class           = shift;
    $class              = ref $class || $class;
    my %args            = @_;
    
    # Check request
    my $http_request;
    if ($args{http_request} && ref $args{http_request} eq "AnyEvent::HTTPD::Request") {
        $http_request = $args{http_request}
    } else {
        cdie("HTTP request isn't defined or has wrong package");
    }
    
    # Check client
    my $client;
    if ($args{client} && ref $args{client} eq "MemoryCache::Client") {
        $client = $args{client};
    } else {
        cdie("Client isn't defined or has wrong package");
    }
    
    # Create cookie
    my $cookie = new MemoryCache::Cookie( http_request => $http_request );
    unless ($cookie->get("session_id") || $cookie->get("session_id") eq $client->get_session_id) {
        $cookie->set("session_id", $client->get_session_id);
    }
    
    
    my $self = {
        http_request    => $http_request,
        client          => $client,
        cookie          => $cookie
    };
    
    bless $self, $class;
    return $self;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub get_http_request {
    my $self = shift;
    return $self->{http_request};
}

sub get_cookie {
    my $self = shift;
    return $self->{cookie};
}

sub get_client {
    my $self = shift;
    return $self->{client};
}

sub send_200 {
    my $self            = shift;
    my $content_type    = shift;
    my $html            = shift;
    $self->{http_request}->respond ([200, 'OK', { %_header, 'Content-Type' => $content_type , $self->$_get_set_cookie() }, $html]);
}

sub send_404 {
    my $self            = shift;
    my $content_type    = shift;
    my $html            = shift;
    $self->{http_request}->respond ([404, 'Not Found', { %_header, 'Content-Type' => $content_type , $self->$_get_set_cookie() }, $html]);
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

1;