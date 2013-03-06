#!perl
use warnings;
use strict;

use Test::More;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 4;

use Net::Twitter::Lite;

my $nt = Net::Twitter::Lite->new(legacy_lists_api => 0);

my $request;
my %args;
my $response = HTTP::Response->new(200, 'OK');
$response->content('{"test":"success"}');

my $cb = sub {
    $request = shift;

    $response->request($request);
    %args = $request->uri->query_form;

    return $response;
};

sub mock_response { shift->{ua}->add_handler(request_send => $cb) }

mock_response($nt);

# additional args in a HASH ref
my $search_term = "intelligent life";
my $r = $nt->search($search_term, { page => 2 });
is $args{q},    $search_term, "q as positional arg";
is $args{page}, 2,            "page parameter set";

# Basic Auth
$nt->credentials('barney','rubble');
$r = $nt->user_timeline;
like $request->header('Authorization'), qr/^Basic /, 'Basic Auth header';

SKIP: {
    eval 'use Net::OAuth 0.25';
    skip "Net::OAuth >= 0.25 required for this test", 1 if $@;

    # NTL fails on methods using HTTP DELETE with OAuth (reported 2011-03-28)
    my $nt = Net::Twitter::Lite->new(
        consumer_key        => 'key',
        consumer_secret     => 'secret',
        access_token        => 'token',
        access_token_secret => 'token_secret',
        legacy_lists_api    => 0,
    );
    mock_response($nt);
    ok eval { $nt->delete_list(fred => 'pets', { -legacy_lists_api => 1}) }, 'HTTP DELETE';
}
