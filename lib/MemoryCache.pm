package MemoryCache;
{
    use strict;
    use AnyEvent;
    use AnyEvent::HTTPD;
    use Coro;
    use Coro::Timer;
    use MemoryCache::StorageDriver;
    use MemoryCache::WebHandler;
    use MemoryCache::ClientManager;
    use Data::Dumper;
    use version;
    
    our $VERSION = qv(0.01);
# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
    
    my $p_httpd_srv;
    my $_web_handler        = new MemoryCache::WebHandler();
    my $p_client_manager    = new MemoryCache::ClientManager();
    my @p_req_handlers      = ();
    
    
    my $p_request_processing = sub {
        my $self = shift;
        my ($httpd, $http_request) = @_;
        async {
            my $client      = $p_client_manager->get_client($http_request);
            my $processing  = $client->add_request($http_request);
            return  if ($processing);
            $_web_handler->process($client);
        };
    };
    
    my $p_initialize = sub {
        my $self = shift;
        my $host = $self->{host} ||= "0.0.0.0";
        my $port = $self->{port} || 0;
        $p_httpd_srv = AnyEvent::HTTPD->new(
            host    => $host,
            port    => $port
        );
        $self->{host}   = $p_httpd_srv->host;
        $self->{port}   = $p_httpd_srv->port;
        $p_httpd_srv->reg_cb (
            request => sub {
                $self->$p_request_processing(@_);
            }
        );
        # Needed to init storages
        new MemoryCache::StorageDriver();
    };

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

    sub new {
        my $class = shift;
        $class = ref $class || $class;
        my %args = @_;
        my $self = {
            config_file => $args{config_file},
            host        => $args{host},
            port        => $args{port},
        };
        bless $self, $class;
        $self->$p_initialize();
        return $self;
    }

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

    sub start {
        $p_httpd_srv->run();
    }

    sub stop {
        $p_httpd_srv->stop();
    }
    
# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
    
}
1;