#!perl
use warnings;
use strict;

use Test::More tests => 2;

use Net::Twitter::Lite;

my $nt = Net::Twitter::Lite->new;

my $request;
my %args;
my $response = HTTP::Response->new(200, 'OK');
$response->content('{"test":"success"}');

$nt->{ua}->add_handler(request_send => sub {
    $request = shift;

    $response->request($request);
    %args = $request->uri->query_form;

    return $response;
});

# additional args in a HASH ref
my $search_term = "intelligent life";
my $r = $nt->search($search_term, { page => 2 });
is $args{q},    $search_term, "q as positional arg";
is $args{page}, 2,            "page parameter set";
