package MemoryCache::Cookie;

use strict;
use MemoryCache::Tools qw/smart_new cdie/;
use Exporter qw/import/;
use Data::Dumper;

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PRIVATE --------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

my $_process_cookies = sub {
    my $self = shift;
    my $cookie_string = $self->{http_request}->headers->{cookie};
    if($cookie_string){
        if($cookie_string =~ /;/){
            my @pairs = split(";", $cookie_string);
            foreach my $pair (@pairs){
                my @item = split("=", $pair);
                $self->{val}->{trim($item[0])} = trim($item[1]);
            }
        } else {
            my @item = split("=", $cookie_string);
            $self->{val}->{trim($item[0])} = trim($item[1]);
        }
    }
};

# /////////////////////////////////////////////////////////////////////////// #
# ------------------------------- CONSTRUCTOR ------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #
   
sub new {
    my %args = smart_new( a => \@_, p => __PACKAGE__);
    cdie("http_request isn't defined") unless $args{http_request};
    my $self = {
        http_request => $args{http_request},
        val        => {},
        new_val    => {}
    };
    bless $self, __PACKAGE__;
    $self->$_process_cookies();
    return $self;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------- PUBLIC ---------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

sub get {
    my $self     = shift;
    my $key        = shift;
    return $self->{val}->{$key};
}

sub set {
    my $self    = shift;
    my $key     = shift;
    my $value   = shift;
    $self->{new_val} = {
        key => $key,
        val => $value
    };
}

sub _set_cookie {
    my $self    = shift;
    return { "Set-Cookie" => $self->{new_val}->{key}."=".$self->{new_val}->{val}} if %{$self->{new_val}};
    return {};
}

sub trim {
    my($string)=@_;
    for ($string) {
        s/^\s+//;
        s/\s+$//;
        }
    return $string;
}

# /////////////////////////////////////////////////////////////////////////// #
# --------------------------------------------------------------------------- #
# /////////////////////////////////////////////////////////////////////////// #

1;