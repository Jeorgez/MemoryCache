package MemoryCache::StorageDriver::Static::Constant;

use strict;
use Carp;
use Data::Dumper;

our @EXPORT = qw/const Const/;
sub import {
    no strict 'refs';
	my $self = shift;
    my $caller = caller;
	defined &$_
		? *{ $caller."::".$_ } = \&$_
		: croak "$_ not exported by $self"
	for (@_ ? @_ : @EXPORT);
}

my %_data = ();

my $_d = sub {
    my $self        = shift;
    my %args        = @_;
    $_data{$self}   = {} unless exists $_data{$self};
    if (%args) {
        foreach my $k (keys %args) {
            $_data{$self}->{$k} = $args{$k};
        }
    }
    return $_data{$self};
};

my $_delete_d = sub {
    my $self = shift;
    delete $_data{$self} if exists $_data{$self};
};

sub new {
    my $class   = shift;
    my $args    = shift || {};
    $class      = ref $class || $class;
    return bless ($args, $class);
}

sub const {
    my $args = shift;
    my $conf = shift || { type => "unknown", default => undef };
    my $self = __PACKAGE__->new($args);
    $self->$_d( %$conf , self => $self);
    return $self;
}

sub Const {
    __PACKAGE__;
}

sub DESTROY {
    my $self = shift;
    $self->$_delete_d;
}

sub get_by_type {
    my $class = shift if ($_[0] eq Const || ref $_[0] eq Const );
    my $type = shift;
    my @result;
    foreach my $conf (keys %_data) {
        my $conf_data = $_data{$conf};
        push (@result, $conf_data->{self}) if ( $conf_data->{type} eq $type );
    }
    return @result;
}

sub type {
	my $self= shift;
	return $self->$_d->{type};
}



1;