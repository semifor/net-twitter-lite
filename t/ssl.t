#!perl
use Test::More;
use Net::Twitter::Lite;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

eval "require Crypt::SSLeay; Crypt::SSLeay->VERSION >= 0.50"
    || plan skip_all => "Crypt::SSLeay 0.50 required: $@";

plan tests => 1;

my $nt = Net::Twitter::Lite->new(ssl => 1, legacy_lists_api => 0);

my $request;
my $response = HTTP::Response->new(200, 'OK');
$response->content('{"test":"success"}');

$nt->{ua}->add_handler(request_send => sub {
    $request = shift;
    $response->request($request);
    return $response;
});

my $r = $nt->search('perl');

like $request->uri, qr/^https:/, 'Search API URL';
