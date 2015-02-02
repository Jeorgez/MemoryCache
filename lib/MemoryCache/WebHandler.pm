package MemoryCache::WebHandler;
{
    use strict;
    use File::Spec;
    use MIME::Types qw(by_suffix by_mediatype import_mime_types);
    use IO::Dir;
    use JSON;
    use URI::Escape;
    
    use Data::Dumper;
    
# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

    my $INIT_FUNCTIONS = {};
    
    my $initialized = 0;
    
    
    my $init = sub {
        unless ($initialized) {
            foreach my $func_name (keys %$INIT_FUNCTIONS) {
                &{$INIT_FUNCTIONS->{$func_name}}();
            }
            $initialized = 1;
        }
    };
    
    my %_path_handlers = ();
    
    my $_add_path_handler = sub {
        my %args    = @_;
        my $path    = $args{path};
        my $handler  = $args{handler};
        $_path_handlers{$path} = $handler unless defined $_path_handlers{$path};
    };
    
# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
    
    sub new {
        my %args        = @_;
        my $self        = {
        };
        bless $self, __PACKAGE__;
        $self->$init();
        return $self;
    }

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
    
    sub process {
        my $self        = shift;
        my $client      = shift;
        while (my $request = $client->get_request()){
            my $url = $request->get_http_request->url;
            foreach my $path (keys %_path_handlers){
                my $search = quotemeta $path;
                if ($url->path =~ /^$search(\/*?(\W|$))/s) {
                    my $url_args = get_url_args($url->query);
                    # Check that arguments don't have special characters
                    next unless check_request_args($request, $url_args, qw/storage table var/);
                    # Path callback
                    my ($ct, $html) = &{$_path_handlers{$path}}($self, $request, %$url_args);
                    # Send response
                    $request->send_200 ($ct, $html);
                }
            }
            $request->send_404 ( "text/html", "<h1>Not Found</h1>");
        }
    }
    
    sub success_response {
        my $hashref     = shift;
        my $response    = {
            success     => 1,
            response    => {
                %$hashref
            }
        };
        my $json    = JSON->new->allow_nonref;
        return $json->encode($response);
    }
    
    sub unsuccess_response {
        my $error_mess  = shift;
        my $hashref     = shift || {};
        my $response    = {
            success     => 0,
            response    => {
                error_message   => $error_mess,
                %$hashref
            }
        };
        my $json    = JSON->new->allow_nonref;
        return $json->encode($response);
    }
    
    sub get_url_args {
        my $query_str = shift;
        my $result = {};
        my @pairs = split("&", $query_str);
        foreach my $pair (@pairs){
            my @item = split("=", $pair);
                $result->{uri_unescape($item[0])} = uri_unescape($item[1]);
        }
        return $result;
    }
    
    sub check_args {
        my $hashref = shift;
        foreach my $arg_key (@_) {
            if($hashref->{$arg_key}){
                unless ($hashref->{$arg_key} =~ /^[a-zA-Z\d_-]*?$/) {
                    return { s => 0, wrong_arg => $arg_key };
                }
            }
        }
        return { s => 1};
    }
    
    sub check_request_args {
        my $request = shift;
        my $argsref = shift;
        my @keys    = @_;
        my $correct_args = &check_args($argsref, @keys);
        unless ($correct_args->{s}) {
            $request->send_200 (
                "application/json",
                unsuccess_response (
                    "Incorrect variable '".$correct_args->{wrong_arg}."'. ".
                    "It contains special characters which aren't allowed. ".
                    "Please, use chars (a-z, A-Z, integer, -, _ )")
            );
            return 0;
        }
        return 1;
    
    }
    
    # ------------------------------------------------------------- #
    # ----------------------- WEB INTERFACE ----------------------- #
    # ------------------------------------------------------------- #
    
    $INIT_FUNCTIONS->{web_interface} = sub {
        &$_add_path_handler(
            path    => "/",
            handler => sub {
                my $self        = shift;
                my $request     = shift;
                my %args        = @_;
                return;
            }
        );
    };
    
    # ------------------------------------------------------------- #
    # --------------------------- FILES --------------------------- #
    # ------------------------------------------------------------- #
    
    $INIT_FUNCTIONS->{files} = sub {
        &$_add_path_handler(
            path    => "/f",
            handler => sub {
                my $self        = shift;
                my $request     = shift;
                my $path = $request->get_http_request->url->path;
                $path =~ s/^\/f/.\/files/;
                if( -d $path){
                    $request->send_404 ( "text/html", "<h1>Not Found</h1>");
                } elsif ( -e $path){
                    my ($mime, $encoding) = by_suffix($path);
                    open (FH, "<".$path);
                    $request->get_http_request->respond({
                        content => [
                            $mime,
                            sub {
                                my ($data_cb) = @_;
                                if($data_cb){
                                    my $buff;
                                    read FH, $buff, 2048, 0;
                                    &$data_cb($buff);
                                }
                            }
                        ]
                    });
                   close(FH);
                }
            }
        );
    };
    
    # ------------------------------------------------------------- #
    # -------------------------- STORAGES ------------------------- #
    # ------------------------------------------------------------- #
    sub storages {
        my $self        = shift;
        my $request     = shift;
        my %args        = @_;
        
        my $s_driver    = $request->get_client->get_storage_driver();
        my @storages    = $s_driver->get_available_storage_names();
        
        my $html  = success_response({
            storages => \@storages
        });
        return ("application/json", $html);
    }
    
    $INIT_FUNCTIONS->{storages} = sub {
        &$_add_path_handler(
            path    => "/rest/storages",
            handler => \&storages
        );
    };
    
    # ------------------------------------------------------------- #
    # ---------------------------- SET ---------------------------- #
    # ------------------------------------------------------------- #
    sub set {
        my $self        = shift;
        my $request     = shift;
        my %args        = @_;
        my $storage     = $args{storage};
        my $table       = $args{table};
        my $var         = $args{var};
        my $value       = $args{value};
        my $time        = $args{time};
        
        my $s_driver    = $request->get_client->get_storage_driver();
        $s_driver->set_storage_name($storage)   if $storage;
        $s_driver->set_table_name($table)       if $table;
        my $method_args = {
            var         => $var,
            value       => $value,
            time        => $time
        };
        my $cv          = AE::cv;
        my $callback    = sub {
            my $result  = shift;
            my $response = success_response( {
                var             => $var,
                value           => $value,
                table           => $s_driver->get_table_name,
                storage         => $s_driver->get_storage_name,
                total_records   => $result->{total},
                expires         => $result->{expires}
             });
            $cv->send($response);
        };
        my $correct_arguments = $s_driver->queue("set", $method_args, $callback);
        my ($html)  = $correct_arguments ? $cv->recv : unsuccess_response("Incorrect arguments for method \"set\"");
        $s_driver->reset;
        return ("application/json", $html);
    }
    
    $INIT_FUNCTIONS->{set} = sub {
        &$_add_path_handler(
            path    => "/rest/set",
            handler => \&set
        );
    };
    # ------------------------------------------------------------- #
    # ---------------------------- GET ---------------------------- #
    # ------------------------------------------------------------- #
    sub get {
        my $self        = shift;
        my $request      = shift;
        my %args        = @_;
        my $storage     = $args{storage};
        my $table       = $args{table};
        my $var         = $args{var};
        
        my $s_driver = $request->get_client->get_storage_driver();
        $s_driver->set_storage_name($storage)   if $storage;
        $s_driver->set_table_name($table)       if $table;
        my $method_args = {
            var     => $var
        };
        my $cv      = AE::cv;
        my $callback = sub {
            my $result  = shift;
            my $response;
            if($result){
                $response = success_response( {
                    var             => $var,
                    table           => $s_driver->get_table_name,
                    storage         => $s_driver->get_storage_name,
                    %$result
                 });
            } else {
                $response = unsuccess_response ( "Variable '".$var."' isn't defined in table '".
                                                $s_driver->get_table_name."' storage '".$s_driver->get_storage_name."'.");
            }
            $cv->send($response);
        };
        my $correct_arguments = $s_driver->queue("get", $method_args, $callback);
        my ($html)  = $correct_arguments ? $cv->recv : unsuccess_response("Incorrect arguments for method \"get\"");
        $s_driver->reset;
        return ("application/json", $html);
        
    }
    
    $INIT_FUNCTIONS->{get} = sub {
        &$_add_path_handler(
            path    => "/rest/get",
            handler => \&get
        );
    };
    # ------------------------------------------------------------- #
    # -------------------------- DELETE --------------------------- #
    # ------------------------------------------------------------- #
    sub delete {
        my $self        = shift;
        my $request     = shift;
        my %args        = @_;
        my $storage     = $args{storage};
        my $table       = $args{table};
        my $var         = $args{var};
        
        
        my $s_driver = $request->get_client->get_storage_driver();
        $s_driver->set_storage_name($storage)   if $storage;
        $s_driver->set_table_name($table)       if $table;
        my $method_args = {
            var         => $var,
        };
        my $cv      = AE::cv;
        my $callback = sub {
            my $total   = shift;
            my $response = success_response ({
                table           => $s_driver->get_table_name,
                storage         => $s_driver->get_storage_name,
                total_records   => $total
             });
            $cv->send($response);
        };
        my $correct_arguments = $s_driver->queue("delete", $method_args, $callback);
        my ($html)  = $correct_arguments ? $cv->recv : unsuccess_response("Incorrect arguments for method \"delete\"");
        $s_driver->reset;
        return ("application/json", $html);
    }
    
    $INIT_FUNCTIONS->{delete} = sub {
        &$_add_path_handler(
            path    => "/rest/delete",
            handler => \&delete
        );
    };
    # ------------------------------------------------------------- #
    # --------------------------- LIST ---------------------------- #
    # ------------------------------------------------------------- #
    sub list {
        my $self        = shift;
        my $request     = shift;
        my %args        = @_;
        my $storage     = $args{storage};
        my $table       = $args{table};
        
        my $s_driver = $request->get_client->get_storage_driver();
        $s_driver->set_storage_name($storage)   if $storage;
        $s_driver->set_table_name($table)       if $table;
        my $cv      = AE::cv;
        my $callback = sub {
            my @list    = @_;
            my $response = success_response ({
                table       => $s_driver->get_table_name,
                storage     => $s_driver->get_storage_name,
                list        => \@list
             });
            $cv->send($response);
        };
        my $correct_arguments = $s_driver->queue("list", {}, $callback);
        my ($html)  = $correct_arguments ? $cv->recv : unsuccess_response("Incorrect arguments for method \"list\"");
        $s_driver->reset;
        return ("application/json", $html);
    }
    
    $INIT_FUNCTIONS->{list} = sub {
        &$_add_path_handler(
            path    => "/rest/list",
            handler => \&list
        );
    };

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

}
1;