package MemoryCache::StorageDriver::Static;

use strict;
use Carp;
use MemoryCache::StorageDriver::Static::Constant;
use Data::Dumper;

use vars qw/$storage_conf $method_conf/;

our @EXPORT = qw/
STORAGE_CLEAN STORAGE_MEMORY STORAGE_SQLITE
STORAGE_LIST
METHOD_GET METHOD_SET METHOD_DELETE METHOD_LIST
STORAGE_METHODS_LIST
check_const_method_name check_method_args
/;
sub import {
    no strict 'refs';
    my $self = shift;
    my $caller = caller;
    defined &$_
        ? *{ $caller.'::'.$_ } = \&$_
        : croak "$_ not exported by $self"
    for (@_ ? @_ : @EXPORT);
}

# /////////////////////////////////////////////////////////////////////////// #
# STORAGES 
# /////////////////////////////////////////////////////////////////////////// #

use constant CONF_STORAGE => {
    type    => "storage",
    default => "name"
};

use constant {
    STORAGE_CLEAN   => const( { name => "clean",   p => "MemoryCache::StorageDriver::StorageMod" },         CONF_STORAGE ),
    STORAGE_MEMORY  => const( { name => "memory",  p => "MemoryCache::StorageDriver::StorageMod::Memory"},  CONF_STORAGE ),
    STORAGE_SQLITE  => const( { name => "sqlite",  p => "MemoryCache::StorageDriver::StorageMod::SQLite"},  CONF_STORAGE ),
};

use constant STORAGE_LIST => (
    Const->get_by_type("storage")
);

# /////////////////////////////////////////////////////////////////////////// #
# METHODS 
# /////////////////////////////////////////////////////////////////////////// #

use constant CONF_METHOD => {
    type    => "method",
    default => "name"
};

use constant {
    METHOD_GET      => const( { name => "get",     required_args   => [ "var" ] },          CONF_METHOD ),
    METHOD_SET      => const( { name => "set",     required_args   => [ "var", "value" ] }, CONF_METHOD ),
    METHOD_DELETE   => const( { name => "delete",  required_args   => [ "var" ] },          CONF_METHOD ),
    METHOD_LIST     => const( { name => "list",    required_args   => [ ] },                CONF_METHOD ),
};

use constant STORAGE_METHODS_LIST => (
    Const->get_by_type("method")
);



# /////////////////////////////////////////////////////////////////////////// #
# STATIC FUNCTIONS 
# /////////////////////////////////////////////////////////////////////////// #

sub check_const_method_name {
    my $method_name = shift;
    if( ref ($method_name) && $method_name->isa(Const) ) {
        if($method_name->type eq CONF_METHOD->{type}) {
            return $method_name;
        }
        
    } else {
        foreach my $method (STORAGE_METHODS_LIST) {
            if($method->{name} eq $method_name){
                return $method;
            }
        }
    }
    
    undef;
}

sub check_method_args {
    my $method_name = shift;
    my $args        = shift;
    my $method         = check_const_method_name ($method_name) || return undef;
    foreach my $arg_name (@{$method->{required_args}}){
        return undef unless defined $args->{$arg_name}; 
    }
    return 1;
}

1;