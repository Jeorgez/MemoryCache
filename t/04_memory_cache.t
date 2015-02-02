#!/usr/bin/perl

use strict;
use AnyEvent;
use MemoryCache;
use MemoryCache::StorageDriver;
use MemoryCache::Tools qw/gen_random_string/;
use URI::Escape;
use Socket;
use JSON;
use Test::More;
use Data::Dumper;

use t::testlib;

sub run_test_case(\%);
sub make_param_str(\%);
sub read_response(*;$);


my $mc_host         = "0.0.0.0";
my $mc_port         = 0;

my $memcache        = new MemoryCache( host => $mc_host, port => $mc_port);
my $storage_driver  = new MemoryCache::StorageDriver();
my $user_sess_id    = gen_random_string(32);

$mc_host            = $memcache->{host};
$mc_port            = $memcache->{port};

my @tests = (
    {
        request_url => "/rest/set",
        params      => {
            var         => "testVar",
            value       => "testValue"
        },
        result      => {
            success     => 1,
            response    => {
                var         => "testVar",
                value       => "testValue",
                table       => $storage_driver->get_table_name,
                storage     => $storage_driver->get_storage_name,
            }
        }
    },
    {
        request_url => "/rest/get",
        params      => {
            var         => "testVar"
        },
        result      => {
            success     => 1,
            response    => {
                var         => "testVar",
                value       => "testValue",
                table       => $storage_driver->get_table_name,
                storage     => $storage_driver->get_storage_name,
            }
        }
    },
    {
        request_url => "/rest/list",
        result      => {
            success     => 1,
            response    => {
                table       => $storage_driver->get_table_name,
                storage     => $storage_driver->get_storage_name,
                list        => [
                    {
                        var         => "testVar",
                        value       => "testValue",
                    }
                ]
            }
        }
    },
    {
        request_url => "/rest/delete",
        params      => {
            var         => "testVar"
        },
        result      => {
            success     => 1,
            response    => {
                table       => $storage_driver->get_table_name,
                storage     => $storage_driver->get_storage_name,
            }
        }
    },
    {
        request_url => "/rest/get",
        params      => {
            var         => "testVar"
        },
        result      => {
            success     => 0,
        }
    },
);

foreach my $test_case (@tests) {
    run_test_case %$test_case;
}

sub run_test_case (\%) {
    my $test_case   = shift;
    my $request_url = $test_case->{request_url};
    my $params      = $test_case->{params};
    my $result      = $test_case->{result};

    my $params_url  = $request_url . make_param_str %$params;
    
    my $req_string  =   "GET ".$params_url." HTTP/1.1\r\n".
                        "Host: $mc_host:$mc_port\r\n".
                        "Cookie: session_id=".$user_sess_id."\r\n".
                        "\r\n";

    my $client      = send_request($req_string, $mc_host, $mc_port);
    my $response    = read_response $client;
    close($client);
    my $body        = get_body ($response);
    my $obj         = decode_json $body;
    my $match       = compare_objects($obj, $result);
    
    
    
    my $result_message  = $match ? "passed" : "failed";
    my $storage         = $obj->{response}->{storage}   || "unknown";
    my $table           = $obj->{response}->{table}     || "unknown";

    ok ($match, "Test for url \"".$request_url."\" ".
                "is ".$result_message." with key success = ".$obj->{success}." ".
                "storage \"".$storage."\", ".
                "table \"".$table."\"");
    
    #print Dumper($obj);
    #print $response."\n";
}

sub make_param_str (\%) {
    my $params      = shift;
    my @keys        = keys %$params;
    my $result;
    foreach my $k (@keys) {
        $result     .= $k eq $keys[0] ? "?" : "&";
        $result     .= uri_escape($k)."=".uri_escape($params->{$k});
    }
    return $result;
}

sub read_response (*;$) {
    my $socket  = shift;
    my $size    = shift || 10;
    my $response;
    my $buff;
    
    my $cv = AE::cv;
    my $sock_io;
    $sock_io = AE::io $socket, 0, sub {
        fail ("Socket isn't defined") unless $socket;
        recv ($socket, $buff, $size, 0);
        if ($buff) {
            $response .= $buff;
        } else {
            $cv->send(1);
            undef $sock_io;
        }
    };
    $cv->recv;
    return $response;
}

sub get_body {
    my $response = shift;
    my $body;
    if ( $response =~ /(\x0D?\x0A){2}(.+?)\Z/ ) {
        $body = $2;
    }
    return $body;
}

sub compare_objects {
    my $obj     = shift;
    my $etalon  = shift;
    if (ref $obj eq ref $etalon) {
        if(ref $obj eq "ARRAY") {
            foreach my $etalon_e (@$etalon) {
                my $found = 0;
                foreach my $obj_e (@$obj){
                    $found = compare_objects($obj_e, $etalon_e);
                }
                return 0 unless $found;
            }
            return 1;
        } elsif (ref $obj eq "HASH") {
            foreach my $key (keys %$etalon) {
                return 0 unless defined $obj->{$key};
                if (ref $etalon->{$key}) {
                    return unless compare_objects($obj->{$key}, $etalon->{$key});
                } else {
                    return 0 unless ($obj->{$key} eq $etalon->{$key});
                }
            }
            return 1;
        } else {
            return $obj eq $etalon;
        }
    }
    return 0;
}

done_testing();