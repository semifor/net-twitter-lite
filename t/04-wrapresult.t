#!perl
use warnings;
use strict;
use Test::More;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $screen_name = 'net_twitter';
my $message_id  = 1234;
my $status      = 'Hello, world!';
my $now = time();

my @tests = (
    # api call              args                                 method  path                     lim  rem  reset
    [ create_block =>       [ { screen_name => $screen_name } ], POST => "/blocks/create.json" ],
    [ direct_messages =>    [ ]                                , GET  => "/direct_messages.json",  15,  14,  $now ],
    [ direct_messages =>    [ ]                                , GET  => "/direct_messages.json",  15,  13,  $now ],
    [ direct_messages =>    [ ]                                , GET  => "/direct_messages.json",  15,  12,  $now ],
    [ favorites =>          [ { screen_name => $screen_name } ], GET  => "/favorites/list.json" ,  15,  14,  $now ],
    [ favorites =>          [ { screen_name => $screen_name } ], GET  => "/favorites/list.json" ,  15,  13,  $now ],
    [ favorites =>          [ { screen_name => $screen_name } ], GET  => "/favorites/list.json" ,  15,  12,  $now ],
    [ followers_list =>     [ { screen_name => $screen_name } ], GET  => "/followers/list.json" ,  15,  14,  $now ],
    [ followers_list =>     [ { screen_name => $screen_name } ], GET  => "/followers/list.json" ,  15,  13,  $now ],
    [ followers_list =>     [ { screen_name => $screen_name } ], GET  => "/followers/list.json" ,  15,  12,  $now ],
    [ friends_list =>       [ { screen_name => $screen_name } ], GET  => "/friends/list.json"   ,  15,  14,  $now ],
    [ friends_list =>       [ { screen_name => $screen_name } ], GET  => "/friends/list.json"   ,  15,  13,  $now ],
    [ friends_list =>       [ { screen_name => $screen_name } ], GET  => "/friends/list.json"   ,  15,  12,  $now ],
    [ new_direct_message => [ { screen_name => $screen_name, text => $status } ], POST => "/direct_messages/new.json" ],
    [ users_search =>       [ { q => $screen_name }           ], GET  => "/users/search.json"   , 180, 179,  $now ],
    [ users_search =>       [ { q => $screen_name }           ], GET  => "/users/search.json"   , 180, 178,  $now ],
    [ users_search =>       [ { q => $screen_name }           ], GET  => "/users/search.json"   , 180, 177,  $now ],
);

plan tests => @tests * 14 + 3;

use_ok 'Net::Twitter::Lite::WithAPIv1_1';

my $nt = Net::Twitter::Lite::WithAPIv1_1->new(ssl => 1,
                                              wrap_result => 1);
isa_ok $nt, 'Net::Twitter::Lite::WithAPIv1_1';

my $limits = {
#   Resource                                  lim  rem  reset
    "/account/settings.json"              => [ 15,  15, $now],
    "/account/verify_credentials.json"    => [ 15,  15, $now],
    "/application/rate_limit_status.json" => [180, 180, $now],
    "/blocks/ids.json"                    => [ 15,  15, $now],
    "/blocks/list.json"                   => [ 15,  15, $now],
    "/direct_messages.json"               => [ 15,  15, $now],
    "/direct_messages/sent.json"          => [ 15,  15, $now],
    "/direct_messages/show.json"          => [ 15,  15, $now],
    "/favorites/list.json"                => [ 15,  15, $now],
    "/followers/ids.json"                 => [ 15,  15, $now],
    "/followers/list.json"                => [ 15,  15, $now],
    "/friends/ids.json"                   => [ 15,  15, $now],
    "/friends/list.json"                  => [ 15,  15, $now],
    "/friendships/incoming.json"          => [ 15,  15, $now],
    "/friendships/lookup.json"            => [ 15,  15, $now],
    "/friendships/no_retweets/ids.json"   => [ 15,  15, $now],
    "/friendships/outgoing.json"          => [ 15,  15, $now],
    "/friendships/show.json"              => [180, 180, $now],
    "/geo/reverse_geocode.json"           => [ 15,  15, $now],
    "/geo/search.json"                    => [ 15,  15, $now],
    "/geo/similar_places.json"            => [ 15,  15, $now],
    "/help/configuration.json"            => [ 15,  15, $now],
    "/help/languages.json"                => [ 15,  15, $now],
    "/help/privacy.json"                  => [ 15,  15, $now],
    "/help/tos.json"                      => [ 15,  15, $now],
    "/lists.json"                         => [ 15,  15, $now],
    "/lists/list.json"                    => [ 15,  15, $now],
    "/lists/members.json"                 => [180, 180, $now],
    "/lists/members/show.json"            => [ 15,  15, $now],
    "/lists/memberships.json"             => [ 15,  15, $now],
    "/lists/ownerships.json"              => [ 15,  15, $now],
    "/lists/show.json"                    => [ 15,  15, $now],
    "/lists/statuses.json"                => [180, 180, $now],
    "/lists/subscribers.json"             => [180, 180, $now],
    "/lists/subscribers/show.json"        => [ 15,  15, $now],
    "/lists/subscriptions.json"           => [ 15,  15, $now],
    "/saved_searches/list.json"           => [ 15,  15, $now],
    "/search/tweets.json"                 => [180, 180, $now],
    "/statuses/home_timeline.json"        => [ 15,  15, $now],
    "/statuses/mentions_timeline.json"    => [ 15,  15, $now],
    "/statuses/oembed.json"               => [180, 180, $now],
    "/statuses/retweeters/ids.json"       => [ 15,  15, $now],
    "/statuses/retweets_of_me.json"       => [ 15,  15, $now],
    "/statuses/user_timeline.json"        => [180, 180, $now],
    "/trends/available.json"              => [ 15,  15, $now],
    "/trends/closest.json"                => [ 15,  15, $now],
    "/trends/place.json"                  => [ 15,  15, $now],
    "/users/contributees.json"            => [ 15,  15, $now],
    "/users/contributors.json"            => [ 15,  15, $now],
    "/users/lookup.json"                  => [180, 180, $now],
    "/users/profile_banner.json"          => [180, 180, $now],
    "/users/search.json"                  => [180, 180, $now],
    "/users/show.json"                    => [180, 180, $now],
    "/users/suggestions.json"             => [ 15,  15, $now],
};

my $ua = $nt->{ua};
my $http_response;

$ua->add_handler(request_send => sub {
    my ($request, $ua, $h) = @_;

    $http_response = HTTP::Response->new(200, 'OK');
    $http_response->request($request);
    $http_response->content('{"test":"success"}');

    my ($resource) = $request->uri =~ m|^https?://api.twitter.com/1.1(.*?)(?:\?.*)?$|;
    if($resource && $limits -> {$resource}) {
        $http_response->header('x-rate-limit-limit' => $limits->{$resource}->[0]);
        $http_response->header('x-rate-limit-remaining' => --$limits->{$resource}->[1]);
        $http_response->header('x-rate-limit-reset' => $limits->{$resource}->[2]);
    }

    return $http_response;
});
use Data::Dumper;
my ($resp, $result, $http_resp);
for my $test ( @tests ) {
    my ($api_call, $args, $method, $path, $limit, $remain, $reset) = @$test;

    my %args;
    if ( $api_call eq 'update' ) {
        %args = ( source => 'twitterpm', status => @$args );
    }
    elsif ( $api_call eq 'relationship_exists' ) {
        @{args}{qw/user_a user_b/} = @$args;
    }
    elsif ( $api_call eq 'update_delivery_device' ) {
        %args = ( device => @$args );
    }
    elsif ( @$args ) {
        %args = ref $args->[0] ? %{$args->[0]} : ( id => $args->[0] );
    }

    ok $resp = $nt->$api_call(@$args), "$api_call call";
    isa_ok $resp, 'Net::Twitter::Lite::WrapResult';
    ok $resp->http_response, "http response available";
    isa_ok $resp->http_response, 'HTTP::Response';

    ok $result = $resp->result, "result is available";
    isa_ok $result, "HASH";
    ok $result->{"test"} eq "success", "test request success";

    if(defined($limit)) {
        ok $limit  == $resp->rate_limit, "$api_call limit = $limit";
        ok $remain == $resp->rate_limit_remaining, "$api_call limit remaining = $remain";
        ok $reset  == $resp->rate_limit_reset, "$api_call limit reset = $reset";
    } else {
        ok !defined($resp->rate_limit), "$api_call no limit";
        ok !defined($resp->rate_limit_remaining), "$api_call no limit remaining";
        ok !defined($resp->rate_limit_reset), "$api_call no reset";
    }

}

$nt = Net::Twitter::Lite::WithAPIv1_1->new(ssl => 1);
isa_ok $nt, 'Net::Twitter::Lite::WithAPIv1_1';

$ua = $nt->{ua};

$ua->add_handler(request_send => sub {
    my ($request, $ua, $h) = @_;

    $http_response = HTTP::Response->new(200, 'OK');
    $http_response->request($request);
    $http_response->content('{"test":"success"}');

    my ($resource) = $request->uri =~ m|^https?://api.twitter.com/1.1(.*?)(?:\?.*)?$|;
    if($resource && $limits -> {$resource}) {
        $http_response->header('x-rate-limit-limit' => $limits->{$resource}->[0]);
        $http_response->header('x-rate-limit-remaining' => --$limits->{$resource}->[1]);
        $http_response->header('x-rate-limit-reset' => $limits->{$resource}->[2]);
    }

    return $http_response;
});


for my $test ( @tests ) {
    my ($api_call, $args, $method, $path, $limit, $remain, $reset) = @$test;

    my %args;
    if ( $api_call eq 'update' ) {
        %args = ( source => 'twitterpm', status => @$args );
    }
    elsif ( $api_call eq 'relationship_exists' ) {
        @{args}{qw/user_a user_b/} = @$args;
    }
    elsif ( $api_call eq 'update_delivery_device' ) {
        %args = ( device => @$args );
    }
    elsif ( @$args ) {
        %args = ref $args->[0] ? %{$args->[0]} : ( id => $args->[0] );
    }

    ok $resp = $nt->$api_call(@$args), "$api_call call";
    isa_ok $resp, "HASH";
    ok(defined $resp && !UNIVERSAL::isa($resp, 'Net::Twitter::Lite::WrapResult'), "$api_call response not wrapped");
    ok $result->{"test"} eq "success", "test request success";
}


exit 0;
