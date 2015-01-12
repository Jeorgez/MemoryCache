package MemoryCache::StorageDriver::StorageMod::Memory;

use strict;
use base "MemoryCache::StorageDriver::StorageMod";
use AnyEvent::Tools qw(mutex);
use MemoryCache::StorageDriver::StorageMod::Memory::Table;

use Data::Dumper;

my @_tables = ();

my $_get_or_create_table = sub {
    my $self        = shift;
    my $table_name  = shift;
    foreach my $table (@_tables){
        if($table->get_name eq $table_name){
            return $table;
        }
    }
    my $new_table = new MemoryCache::StorageDriver::StorageMod::Memory::Table($table_name);
    push (@_tables, $new_table);
    return $new_table;
};

sub new {
    my $class   = shift;
    $class      = ref $class || $class;
    my $self = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub set {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    my $value       = $args{value};
    my $time        = $args{expires};
    my $table       = $self->$_get_or_create_table($table_name);
    my $total       = $table->set(
        %args
    );
    return $total;
}

sub get {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    my $table       = $self->$_get_or_create_table($table_name);
    my $response    = $table->get(
        %args
    );
    return $response;
}

sub delete {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    my $table       = $self->$_get_or_create_table($table_name);
    my $response    = $table->delete(
        %args
    );
    return $response;
}

sub list {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $table       = $self->$_get_or_create_table($table_name);
    my @list        = $table->list();
    return @list;
}

1;