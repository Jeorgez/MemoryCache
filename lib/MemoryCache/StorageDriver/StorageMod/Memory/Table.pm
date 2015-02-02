package MemoryCache::StorageDriver::StorageMod::Memory::Table;

use strict;
use AnyEvent::Tools qw(mutex);
use Data::Dumper;

sub new {
    my $class   = shift;
    $class      = ref $class || $class;
    my $name    = shift;
    my $self    = {
        name        => $name,
        t_mutex     => mutex,
        data        => {}
    };
    bless  $self, __PACKAGE__;
    return $self;
}

sub get_name {
    my $self = shift;
    return $self->{name};
}

sub get_mutex {
    my $self = shift;
    return $self->{t_mutex};
}

sub get_data {
    my $self = shift;
    return $self->{data};
}

sub set {
    my $self        = shift;
    my %args        = @_;
    my $var         = $args{var};
    my $value       = $args{value};
    my $expires     = $args{expires};
    $self->{data}->{$var} = {
        value   => $value,
        expires => $expires
    };
    my $total = scalar keys %{$self->{data}};
    return {
        total       => $total,
        expires     => $expires
    };
}

sub get {
    my $self        = shift;
    my %args        = @_;
    my $var         = $args{var};
    return $self->{data}->{$var};
}

sub delete {
    my $self        = shift;
    my %args        = @_;
    my $var         = $args{var};
    delete $self->{data}->{$var};
    return scalar keys %{$self->{data}};
}

sub list {
    my $self = shift;
    my @result = ();
    foreach my $var (keys %{$self->{data}}){
        push @result, { var => $var, %{$self->{data}->{$var}}};
    }
    
    return @result;
}

1;