#!/usr/bin/perl

use strict;
use Test::More;
use MemoryCache::StorageDriver;
use MemoryCache::StorageDriver::Static;

use t::testlib;

test_case {
    my $storage_driver      = new MemoryCache::StorageDriver();
    
    my $def_storage_name    = $storage_driver->get_storage_name;
    my $def_table_name      = $storage_driver->get_table_name;
    
    my $set_storage_name    = STORAGE_CLEAN->{name};
    my $set_table_name      = "anytable";
    
    $storage_driver->set_storage_name($set_storage_name);
    $storage_driver->set_table_name($set_table_name);
    
    is ($storage_driver->get_storage_name,  $set_storage_name,  "Method to set storage name works ok");
    is ($storage_driver->get_table_name,    $set_table_name,    "Method to set table name works ok");
    
    $storage_driver->reset; # Reset to default values
    
    ok ($storage_driver->get_storage_name ne $set_storage_name, "Method to reset storage name works ok");
    ok ($storage_driver->get_table_name ne $set_table_name,     "Method to reset table name works ok");
    
	# Set new defaults values
    $storage_driver->set_def_storage_name($set_storage_name);
    $storage_driver->set_def_table_name($set_table_name);
    
    is ($storage_driver->get_storage_name,  $set_storage_name,  "Method to set default storage name works ok");
    is ($storage_driver->get_table_name,    $set_table_name,    "Method to set default table name works ok");
    
    my @storages = $storage_driver->get_available_storage_names;
    
    foreach my $storage_name (@storages){
        #print "$storage_name \n";
        my $result = &check_storage_handler($storage_driver, $storage_name);
        ok ($result, "Storage \"$storage_name\" is created and its handler is running");
    }
};

sub check_storage_handler {
    my $storage_driver  = shift;
    my $storage_name    = shift;
    my $cv              = AE::cv;
    $storage_driver->set_storage_name($storage_name);
    $storage_driver->queue (
        # method name
        "get",
        # arguments
        {
            table   => "test",
            var     => "test"
        },
        # callback
        sub {
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
    return $result;
}

done_testing();