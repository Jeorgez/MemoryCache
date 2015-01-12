package MemoryCache;
{
    use strict;
    use AnyEvent;
    use AnyEvent::HTTPD;
    use Coro;
    use Coro::Timer;
    use MemoryCache::WebHandler;
    use MemoryCache::ClientManager;

    use MemoryCache::Handler;
    #use Data::Dumper;
    #use version;
    
    #our $VERSION = qv(0.01);
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
        $p_httpd_srv = AnyEvent::HTTPD->new( port => 8082 );
        $p_httpd_srv->reg_cb (
            request => sub {
                $self->$p_request_processing(@_);
            }
        );
    };

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

    sub new {
        my %args = @_;
        my $self = {
            config_file => $args{config_file}
        };
        bless $self, __PACKAGE__;
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
        async {
            $p_httpd_srv->stop();
        };
    }

    sub restart {
        my $self = shift;
        $self->start();
        $self->stop();
    }
    
# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
    
}
1;