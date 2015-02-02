#!/usr/bin/perl

use strict;
use AnyEvent;
use Test::More;
use MemoryCache::StorageDriver::StorageMod;

use t::testlib;

test_case {
    note("Run storage handler");
    my $storage_mod = new MemoryCache::StorageDriver::StorageMod();
    my $cv          = AE::cv;
    $storage_mod->run_handler();
    my $status = $storage_mod->get_handler_status();
    
    ok ($status, "Handler status - running");
    
    $storage_mod->add_task (
        method      => $storage_mod->can("get"),
        method_args => {
            table       => "default",
            storage     => "default"
        },
        callback    => sub {
            $cv->send(1);
        }
    );
    my $timeout_timer = AnyEvent->timer(
        after   => 1,
        cb      => sub {
            $cv->send(0);
        }
    );
    my $result = $cv->recv;
    undef $timeout_timer;
    
    ok ($result, "Handler calls the task callback");
    
    note("Stop storage handler");
    $storage_mod->stop_handler();
    my $status = $storage_mod->get_handler_status();
    
    ok ($status eq undef, "Handler status - shutdown");
};

done_testing();