#!perl
use warnings;
use strict;
use Test::More;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $screen_name = 'net_twitter';
my $message_id  = 1234;
my $status      = 'Hello, world!';

my @tests = (
    [ create_block           => [ { screen_name => $screen_name } ], POST => "/blocks/create.json"   ],
    [ create_favorite        => [ $message_id           ], POST => "/favorites/create.json" ],
    [ create_favorite        => [ { id => $message_id } ], POST => "/favorites/create.json" ],
    [ create_friend          => [ { screen_name => $screen_name } ], POST => "/friendships/create.json" ],
    [ destroy_block          => [ { screen_name => $screen_name } ], POST => "/blocks/destroy.json"  ],
    [ destroy_direct_message => [ $message_id           ], POST => "/direct_messages/destroy.json" ],
    [ destroy_favorite       => [ $message_id           ], POST => "/favorites/destroy.json" ],
    [ destroy_favorite       => [ { id => $message_id } ], POST => "/favorites/destroy.json" ],
    [ destroy_friend         => [ { screen_name => $screen_name } ], POST => "/friendships/destroy.json" ],
    [ destroy_status         => [ $message_id           ], POST => "/statuses/destroy/$message_id.json"  ],
    [ destroy_status         => [ { id => $message_id } ], POST => "/statuses/destroy/$message_id.json"  ],
    [ direct_messages        => [],                        GET  => "/direct_messages.json"               ],
    [ favorites              => [],                        GET  => "/favorites/list.json"                ],
    [ followers              => [],                        GET  => "/followers/list.json"                ],
    [ friends                => [],                        GET  => "/friends/list.json"                  ],
    [ new_direct_message     => [ { screen_name => $screen_name, text => $status } ],
             POST => "/direct_messages/new.json" ],
    [ rate_limit_status      => [],                        GET  => "/application/rate_limit_status.json" ],
    [ mentions               => [],                        GET  => "/statuses/mentions_timeline.json"    ],
    [ sent_direct_messages   => [],                        GET  => "/direct_messages/sent.json"          ],
    [ show_status            => [ $message_id ], GET  => "/statuses/show/$message_id.json" ],
    [ show_user              => [ { screen_name => $screen_name } ], GET  => "/users/show.json" ],
    [ update                 => [ $status               ], POST => "/statuses/update.json"               ],
    [ update_delivery_device => [ 'sms'                 ], POST => "/account/update_delivery_device.json" ],
    [ update_profile         => [ { name => $screen_name } ], POST => "/account/update_profile.json"     ],
    [ update_profile_background_image => [ { image => 'binary' }          ],
             POST => "/account/update_profile_background_image.json"      ],
    [ update_profile_colors  => [ { profile_background_color => '#0000' } ],
             POST => "/account/update_profile_colors.json"                ],
    [ update_profile_image   => [ { image => 'binary data here' }         ],
             POST => "/account/update_profile_image.json"                 ],
    [ user_timeline          => [],                        GET  => "/statuses/user_timeline.json"         ],
    [ verify_credentials     => [],                        GET  => "/account/verify_credentials.json"     ],
);

plan tests => @tests * 4 + 2;

use_ok 'Net::Twitter::Lite::WithAPIv1_1';

my $nt = Net::Twitter::Lite::WithAPIv1_1->new;
isa_ok $nt, 'Net::Twitter::Lite::WithAPIv1_1';

my $ua = $nt->{ua};
my $http_response;

$ua->add_handler(request_send => sub {
    my ($request, $ua, $h) = @_;

    $http_response = HTTP::Response->new(200, 'OK');
    $http_response->request($request);
    $http_response->content('{"test":"success"}');

    return $http_response;
});

sub input_args {
    my $req = shift;
    
    my $uri = $req->uri->clone;
    my %args = $uri->query_form;

    if ( $uri->path =~ /\/($screen_name|$message_id)\.json$/ ) {
        $args{id} = $1;
    }

    $uri->query($req->content);
    return { %args, $uri->query_form };
}

for my $test ( @tests ) {
    my ($api_call, $args, $method, $path) = @$test;

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

    ok $nt->$api_call(@$args),         "$api_call call";
    my $req = $http_response->request;

    (my $path_part = $req->uri->path) =~ s{^/1\.1}{};

    is_deeply input_args($req), \%args,   " $api_call args";
    is $path_part,              $path,    " $api_call path";
    is $req->method,            $method,  " $api_call method";
}

exit 0;
