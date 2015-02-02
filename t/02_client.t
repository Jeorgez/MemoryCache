#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use MemoryCache::Client;
use MemoryCache::StorageDriver;
use MemoryCache::Tools qw/gen_random_string/;

use t::testlib;

test_case {
    note("Creating client without storage driver");
    my $session_id  = gen_random_string(32);
    my $client      = new MemoryCache::Client(
        session_id  => $session_id
    );
    is ($client->get_session_id, $session_id,   "Session id is correct");
    ok ($client->get_storage_driver,            "Storage driver was created in constructor");
};

test_case {
    note("Creating client with storage driver");
    my $session_id      = gen_random_string(32);
    my $storage_driver  = new MemoryCache::StorageDriver();
    my $client          = new MemoryCache::Client(
        session_id      => $session_id,
        storage_driver  => $storage_driver
    );
    is ($client->get_session_id,        $session_id,        "Session id is correct");
    is ($client->get_storage_driver,    $storage_driver,    "Storage driver is correct");
};

req_test_case {
    my ($httpd, $http_request) = @_;
    note("Request handling");
    my $session_id      = gen_random_string(32);
    my $storage_driver  = new MemoryCache::StorageDriver();
    my $client          = new MemoryCache::Client(
        session_id      => $session_id,
        storage_driver  => $storage_driver
    );
    my $processing      = $client->add_request($http_request);
    ok ($processing eq 0, "Processing flag is 0 as default");
    my $shift_request   = $client->get_request()->get_http_request;
    is ($shift_request, $http_request, "Pool of requests is working");
};



done_testing();