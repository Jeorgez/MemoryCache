package t::testlib;

use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTPD;
use Socket;
use Carp;
use Test::More;

use Data::Dumper;

our @EXPORT = qw/test_case req_test_case send_request/;

my $httpd;
&create_httpd();

my $httpd_host = $httpd->host;
my $httpd_port = $httpd->port;

sub import {
    no strict 'refs';
	my $self = shift;
    my $caller = caller;
	defined &$_
		? *{ $caller.'::'.$_ } = \&$_
		: croak "$_ not exported by $self"
	for (@_ ? @_ : @EXPORT);
}

sub test_case(&) { &{shift @_}(); }

sub req_test_case(&@) {
    my $cb          = \&{shift @_};
    my $req_string  = shift || "GET / HTTP/1.1\r\nHost: $httpd_host\r\n\r\n";
    print "$req_string";
    my $cv = AnyEvent->condvar;
    my $req_cb_gen;
    my $req_cb = sub {
        my ($httpd, $http_request) =@_;
        &$cb(@_);
        $http_request->respond([200, 'OK', { 'Content-Type' => "text/html" }, "OK"]);
        $httpd->unreg_cb($req_cb_gen);
        $httpd->stop();
        $cv->send(1);
    };
    $req_cb_gen = $httpd->reg_cb (
        request => $req_cb
    );
    my $client = &send_request($req_string);
    my $timeout_timer = AnyEvent->timer(
        after   => 15,
        cb      => sub {
            $httpd->stop();
            $cv->send(0);
        }
    );
    $httpd->run();
    my $result = $cv->recv;
    close($client);
    undef $timeout_timer;
    fail ("HTTPD server isn't working") unless $result;
    
}

sub send_request {
    my $req_string  = shift;
    my $server_host = shift || $httpd_host;
    my $server_port = shift || $httpd_port;
    $server_host = "127.0.0.1" if $server_host eq "0.0.0.0";
    my $client;
    # Create client connection and send data
    socket($client, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
    my $iaddr = inet_aton($server_host);
    my $paddr = sockaddr_in($server_port, $iaddr);
    connect($client, $paddr);
    my $send_len = send ($client, $req_string, 0);
    return $client;
}

sub create_httpd {
    $httpd = new AnyEvent::HTTPD();
}

1;