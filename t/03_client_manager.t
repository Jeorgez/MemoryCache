#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use MemoryCache::ClientManager;
use MemoryCache::Tools qw/gen_random_string/;

use t::testlib;


my $session_id = gen_random_string(32);
my $req_string = "GET /testRequest HTTP/1.1\nHost:127.0.0.1\nCookie:session_id=".$session_id."\n\n";

req_test_case {
    my ($httpd, $http_request) = @_;
    my $client_manager      = new  MemoryCache::ClientManager();
    my $original_client     = $client_manager->create_client($session_id);
    my $find_client         = $client_manager->find_client($session_id);
    my $get_client          = $client_manager->get_client($http_request);
    ok(ref $original_client eq "MemoryCache::Client", "Method create is working");
    is($find_client,    $original_client, "Method find is working");
    is($get_client,     $original_client, "Method get is working");
} $req_string;

done_testing();