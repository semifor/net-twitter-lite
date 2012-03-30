#!perl
use warnings;
use strict;
use Test::More;
use Net::Twitter::Lite;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $nt = Net::Twitter::Lite->new(username => 'fred', password => 'secret', legacy_lists_api => 0);

my $req;
my $res = HTTP::Response->new(200);
$res->content('{"response":"done"}');
$nt->{ua}->add_handler(request_send => sub { $req = shift; return $res });

my @tests = (
    create_list => {
        args   => [ { name => 'Test list', description => 'Just a test', mode => 'private' } ],
        path   => '/lists/create',
        params => { name => 'Test list', description => 'Just a test', mode => 'private' },
        method => 'POST',
    },
    update_list => {
        args   => [ { owner_screen_name => 'owner', slug => 'test-list', mode => 'public' } ],
        path   => '/lists/update',
        params => {  owner_screen_name => 'owner', slug => 'test-list', mode => 'public' },
        method => 'POST',
    },
    list_lists => {
        args =>[ { owner_screen_name => 'owner' } ],
        path => '/lists',
        params => { owner_screen_name => 'owner' },
        method => 'GET',
    },
    list_memberships => {
        args => [],
        path => '/lists/memberships',
        params => {},
        method => 'GET',
    },
    delete_list => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list' } ],
        path => '/lists/destroy',
        params => { owner_screen_name => 'owner', slug => 'test-list' },
        method => 'POST',
    },
    list_statuses => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list' } ],
        path => '/lists/statuses',
        params => { owner_screen_name => 'owner', slug => 'test-list' },
        method => 'GET',
    },
    get_list => {
        args => [ { owner_srceen_name => 'owner', slug => 'test-list' } ],
        path => '/lists/show',
        params => { owner_srceen_name => 'owner', slug => 'test-list' },
        method => 'GET',
    },
    add_list_member => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/members/create',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'POST',
    },
    delete_list_member => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/members/destroy',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'POST',
    },
    remove_list_member => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/members/destroy',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'POST',
    },
    list_members => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list' } ],
        path => '/lists/members',
        params => { owner_screen_name => 'owner', slug => 'test-list' },
        method => 'GET',
    },
    is_list_member => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/members/show',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'GET',
    },
    subscribe_list => {
        args => [ { owner_screen_name => 'owner', slug => 'some-list' } ],
        path => '/lists/subscribers/create',
        params => { owner_screen_name => 'owner', slug => 'some-list' },
        method => 'POST',
    },
    list_subscribers => {
        args => [ { owner_screen_name => 'owner', slug => 'some-list' } ],
        path => '/lists/subscribers',
        params => { owner_screen_name => 'owner', slug => 'some-list' },
        method => 'GET',
    },
    list_subscriptions => {
        args => [],
        path => '/lists/all',
        params => {},
        method => 'GET',
    },
    unsubscribe_list => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list' } ],
        path => '/lists/subscribers/destroy',
        params => { owner_screen_name => 'owner', slug => 'test-list' },
        method => 'POST',
    },
    is_list_subscriber => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/subscribers/show',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'GET',
    },
    is_subscribed_list => {
        args => [ { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 } ],
        path => '/lists/subscribers/show',
        params => { owner_screen_name => 'owner', slug => 'test-list', user_id => 1234 },
        method => 'GET',
    },
    members_create_all => {
        args => [ { list_id => 9876, screen_name => [qw/bert barney fred/] }],
        path => '/lists/members/create_all',
        params => { list_id => 9876, screen_name => 'bert,barney,fred' },
        method => 'POST',
    },
    add_list_members => {
        args => [ { list_id => 9876, screen_name => [qw/bert barney fred/] }],
        path => '/lists/members/create_all',
        params => { list_id => 9876, screen_name => 'bert,barney,fred' },
        method => 'POST',
    },
    remove_list_members => {
        args => [ { list_id => 9876, screen_name => [qw/bert barney fred/] }],
        path => '/lists/members/destroy_all',
        params => { list_id => 9876, screen_name => 'bert,barney,fred' },
        method => 'POST',
    },
    get_lists => {
        args => [ { screen_name => 'owner' } ],
        path => '/lists',
        params => { screen_name => 'owner' },
        method => 'GET',
    },
    subscriptions => {
        args => [],
        path => '/lists/subscriptions',
        params => {},
        method => 'GET',
    },
);

plan tests => scalar @tests / 2 * 3 + 2;

while ( @tests ) {
    my $api_method = shift @tests;
    my $t = shift @tests;

    my $r = $nt->$api_method(@{ $t->{args} });
    is $req->uri->path, "/1$t->{path}.json", "$api_method: path";
    is $req->method, $t->{method}, "$api_method: HTTP method";
    is_deeply extract_args($req), $t->{params},
        "$api_method: parameters";
}

{
    # unauthenticated call
    my $r = $nt->list_statuses({ owner_screen_name => 'twitter' => slug => 'team', authenticate => 0 });
    ok !$req->header('authorization'), 'unauthenticated call';

    # authenticated call (default)
    $r = $nt->list_statuses({ owner_screen_name => 'twitter' => slug => 'team' });
    like $req->header('authorization'), qr/^Basic/, 'authenticated request (default)';
}

sub extract_args {
    my $req = shift;

    my $uri;
    if ( $req->method eq 'POST' ) {
        $uri = URI->new;
        $uri->query($req->content);
    }
    else {
        $uri = $req->uri;
    }

    return { $uri->query_form };
}
