#!/usr/bin/perl
#
# Net::Twitter::Lite - OAuth webapp example
#
package MyWebApp;
use warnings;
use strict;
use base qw/HTTP::Server::Simple::CGI/;

use Data::Dumper;
use Net::Twitter::Lite::WithAPIv1_1;

# You can replace the consumer tokens with your own;
# these tokens are for the Net::Twitter example app.
my %consumer_tokens = (
    consumer_key    => 'v8t3JILkStylbgnxGLOQ',
    consumer_secret => '5r31rSMc0NPtBpHcK8MvnCLg2oAyFLx5eGOMkXM',
);

my $server_port = 8080;

# The server needs to store request tokens/secrets. When a user is returned
# from Twitter's authentication flow to our callback URL, the request token
# will be included in the callback parameters. We'll look up the secret that
# matches the token. It will be used to obtain an access token/secret.  Request
# tokens are only good for about 15 minutes.
#
# In a production app, you'll want to use something like Redis to automatically
# expire secrets after 20 minutes or so. (Keep them a bit longer than Twitter
# so Twitter drops them first. You don't want to surprise users who authorize
# on Twitter and then you faile to find the secret you need to obtain access
# tokens.
#
# For our simple demo, we'll just store them in memory with expiration.
my $request_token_cache = {};

# We only need it once!
sub get_secret { delete $request_token_cache->{shift()} }
sub set_secret { $request_token_cache->{$_[0]} = $_[1]  }

sub twitter_client {
    Net::Twitter::Lite::WithAPIv1_1->new(%consumer_tokens);
}

my %dispatch = (
    '/oauth_callback' => \&oauth_callback,
    '/'               => \&my_last_tweet,
);


# all request start here
sub handle_request {
    my ($self, $q) = @_;

    my $request = $q->path_info;
    warn "Handling request for ${ \$q->url(-full => 1) }\n";

    my $handler = $dispatch{$request} || \&not_found;
    $self->$handler($q);
}

# Display the authenicated user's last tweet
sub my_last_tweet {
    my ($self, $q) = @_;

    # if the user is authorized, we'll get access tokens from a cookie
    my %tokens = $q->cookie('dont-do-this');

    unless ( %tokens ) {
        warn "User has no access_tokens\n";
        return $self->authorize($q);
    }

    warn <<"";
Using access tokens:
   access_token        => $tokens{access_token}
   access_token_secret => $tokens{access_token_secret}

    my $nt = $self->twitter_client;

    # pass the access tokens to Net::Twitter::Lite
    $nt->access_token($tokens{access_token});
    $nt->access_token_secret($tokens{access_token_secret});

    # attempt to get the user's last tweet
    my $status = eval { $nt->user_timeline({ count => 1 }) };
    if ( $@ ) {
        warn "$@\n";

        # if we got a 401 response, our access tokens were invalid; get new ones
        return $self->authorize($q, $nt) if $@ =~ /\b401\b/;

        # something bad happened; show the user the error
        $status = $@;
    }

    print $q->header(-nph => 1),
          $q->start_html,
          $q->pre(Dumper $status),
          $q->end_html;
}

# send the user to Twitter to authorize us
sub authorize {
    my ($self, $q, $nt) = @_;
    $nt ||= $self->twitter_client;

    my $callback = join '', $ENV{SERVER_URL}, 'oauth_callback';
    my $auth_url = $nt->get_authorization_url(
        callback => $callback,
    );

    set_secret(
        $nt->request_token,
        $nt->request_token_secret
    );

    warn "Sending user to: $auth_url\n";
    print $q->redirect(-nph => 1, -uri => $auth_url);
}

# Twitter returns the user here
sub oauth_callback {
    my ($self, $q) = @_;

    # If the user authorized the app, we'll get oauth_token and oauth_verifier
    # parameters. If they hit "cancel" to deny the request, then the "return to
    # ..." button, we'll ge the request_token back in the "denied" parameter.
    if ( my $token = $q->param('denied') ) {
        warn "Sadly, we were denied for request_token $token.\n";
        get_secret($token); # discard it, it's of no value, now
        print $q->redirect(-nph => 1, -uri => "$ENV{SERVER_URL}");
        return;
    }

    my $request_token  = $q->param('oauth_token');
    my $verifier       = $q->param('oauth_verifier');
    my $request_secret = get_secret($request_token);
    unless ( $request_secret ) {
        # Something is wrong:
        # - the request_token has expired
        # - our callback was hit with invalid parameters
        # - this is a replay (we've already exchanged the request token
        #   for an access token/secret
        # Your app will need to deal with it. We'll punt the user to
        # the home page.
        print $q->redirect(-nph => 1, -uri => "$ENV{SERVER_URL}");
        return;
    }

    warn <<"";
User returned from Twitter with:
    oauth_token    => $request_token
    oauth_verifier => $verifier

    # We'll need the request token/secret for authorization
    my $nt = $self->twitter_client;
    $nt->request_token($request_token);
    $nt->request_token_secret($request_secret);

    # exchange the request token for access tokens
    my ( $access_token, $access_token_secret ) =
        $nt->request_access_token(verifier => $verifier);

    warn <<"";
Exchanged request tokens for access tokens:
    access_token        => $access_token
    access_token_secret => $access_token_secret

    # *** Don't do this at home! ***
    # For our simple example, we'll store the access token/secret in a cookie.
    # In a production app, you don't want to do this. Store the token/secret
    # in a database, encrypted!
    my $cookie = $q->cookie(-name => 'dont-do-this', -value => {
        access_token        => $access_token,
        access_token_secret => $access_token_secret,
    });

    warn "redirecting newly authorized user to $ENV{SERVER_URL}\n";
    print $q->redirect(-cookie => $cookie, -nph => 1, -uri => "$ENV{SERVER_URL}");
}

# display a 404 Not found for any request we don't expect
sub not_found {
    my ($self, $q) = @_;

    print $q->header(-nph => 1, -type => 'text/html', -status => '404 Not found'),
          $q->start_html,
          $q->h1('Not Found'),
          $q->p('You appear to be lost. Try going home.');
}

my $app = MyWebApp->new($server_port);
$app->run;
