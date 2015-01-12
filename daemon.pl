#!/usr/bin/perl

use strict;
use AnyEvent::HTTPD;
use MemoryCache;

my $memcache = new MemoryCache();
$memcache->start();

# my $httpd_server = AnyEvent::HTTPD->new (port => 8081);

# $httpd_server->reg_cb (
#     '/' => sub {
# 		my ($httpd_server, $req) = @_;
# 		$req->respond ({ content => ['text/html',
#         "<html><body><h1>Hello World!</h1>"
#         . "<a href=\"/test\">another test page</a>"
#         . "</body></html>"
#         ]});
#        },
#     '/test' => sub {
#           my ($httpd_server, $req) = @_;

#           $req->respond ({ content => ['text/html',
#              "<html><body><h1>Test page</h1>"
#              . "<a href=\"/\">Back to the main page</a>"
#              . "</body></html>"
#           ]});
#        },
# );

# $httpd_server->run;