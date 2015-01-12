package MemoryCache::Handler;

use strict;
use MemoryCache::Tools qw/smart_new cdie/;

sub new {
    my %args = smart_new( a => \@_, p => __PACKAGE__);
    cdie ( "http_path isn't defined.\nDump: ". Dumper(\%args)) unless ($args{http_path});
    cdie ( "function (f) isn't defined.\nDump: ". Dumper(\%args)) unless (($args{f} || ref ($args{f}) eq "CODE"));
    my $self = {
        %args
    };
    bless $self, __PACKAGE__;
    return $self;
}







1;