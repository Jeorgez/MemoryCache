#!/usr/bin/perl

use strict;
use AnyEvent::HTTPD;
use MemoryCache;

my $memcache = new MemoryCache( host => "0.0.0.0", port => 18080);
$memcache->start();