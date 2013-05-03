package Net::Twitter::Lite;
use 5.005;
use warnings;
use strict;

=head1 NAME

Net::Twitter::Lite - A perl library for Twitter's API v1

=cut

our $VERSION = '0.12003';

use Carp;
use URI::Escape;
use JSON;
use HTTP::Request::Common;
use Net::Twitter::Lite::Error;
use Encode qw/encode_utf8/;

sub twitter_api_def_from           () { 'Net::Twitter::Lite::API::V1' }
sub _default_api_url               () { 'http://api.twitter.com/1'    }
sub _default_searchapiurl          () { 'http://search.twitter.com'   }
sub _default_search_trends_api_url () { 'http://api.twitter.com/1'    }
sub _default_lists_api_url         () { 'http://api.twitter.com/1'    }

my $json_handler = JSON->new->utf8;

sub new {
    my ($class, %args) = @_;

    $class->can('verify_credentials') || $class->build_api_methods;

    my $netrc = delete $args{netrc};
    my $new = bless {
        apiurl                => $class->_default_api_url,
        searchapiurl          => $class->_default_searchapiurl,
        search_trends_api_url => $class->_default_search_trends_api_url,
        lists_api_url         => $class->_default_lists_api_url,
        apirealm   => 'Twitter API',
        $args{identica} ? ( apiurl => 'http://identi.ca/api' ) : (),
        useragent  => (ref $class || $class) . "/$VERSION (Perl)",
        clientname => (ref $class || $class),
        clientver  => $VERSION,
        clienturl  => 'http://search.cpan.org/dist/Net-Twitter-Lite/',
        source     => 'twitterpm',
        useragent_class => 'LWP::UserAgent',
        useragent_args  => {},
        oauth_urls => {
            request_token_url  => "https://api.twitter.com/oauth/request_token",
            authentication_url => "https://api.twitter.com/oauth/authenticate",
            authorization_url  => "https://api.twitter.com/oauth/authorize",
            access_token_url   => "https://api.twitter.com/oauth/access_token",
            xauth_url          => "https://api.twitter.com/oauth/access_token",
        },
        netrc_machine => 'api.twitter.com',
        %args
    }, $class;

    unless ( exists $new->{legacy_lists_api} ) {
        $new->{legacy_lists_api} = 1;
        carp
"For backwards compatibility @{[ __PACKAGE__ ]} uses the deprecated Lists API
endpoints and semantics. This default will be changed in a future version.
Please update your code to use the new lists semantics and pass
(legacy_lists_api => 0) to new.

You can disable this warning, and keep backwards compatibility by passing
(legacy_lists_api => 1) to new. Be warned, however, that support for the
legacy endpoints will be removed in a future version and the default will
change to (legacy_lists_api => 0).";

    }

    if ( delete $args{ssl} ) {
        $new->{$_} =~ s/^http:/https:/
            for qw/apiurl searchapiurl search_trends_api_url lists_api_url/;
    }

    # get username and password from .netrc
    if ( $netrc ) {
        eval { require Net::Netrc; 1 }
            || croak "Net::Netrc is required for the netrc option";

        my $host = $netrc eq '1' ? $new->{netrc_machine} : $netrc;
        my $nrc = Net::Netrc->lookup($host)
            || croak "No .netrc entry for $host";

        @{$new}{qw/username password/} = $nrc->lpa;
    }

    $new->{ua} ||= do {
        eval "use $new->{useragent_class}";
        croak $@ if $@;

        $new->{useragent_class}->new(%{$new->{useragent_args}});
    };

    $new->{ua}->agent($new->{useragent});
    $new->{ua}->default_header('X-Twitter-Client'         => $new->{clientname});
    $new->{ua}->default_header('X-Twitter-Client-Version' => $new->{clientver});
    $new->{ua}->default_header('X-Twitter-Client-URL'     => $new->{clienturl});
    $new->{ua}->env_proxy;

    $new->{_authenticator} = exists $new->{consumer_key}
                           ? '_oauth_authenticated_request'
                           : '_basic_authenticated_request';

    $new->credentials(@{$new}{qw/username password/})
        if exists $new->{username} && exists $new->{password};

    return $new;
}

sub credentials {
    my $self = shift;
    my ($username, $password) = @_;

    croak "exected a username and password" unless @_ == 2;
    croak "OAuth authentication is in use"  if exists $self->{consumer_key};

    $self->{username} = $username;
    $self->{password} = $password;

    my $uri = URI->new($self->{apiurl});
    my $netloc = join ':', $uri->host, $uri->port;

    $self->{ua}->credentials($netloc, $self->{apirealm}, $username, $password);
}

# This is a hack. Rather than making Net::OAuth an install requirement for
# Net::Twitter::Lite, require it at runtime if any OAuth methods are used.  It
# simply returns the string 'Net::OAuth' after successfully requiring
# Net::OAuth.
sub _oauth {
    my $self = shift;

    return $self->{_oauth} ||= do {
        eval "use Net::OAuth 0.25";
        croak "Install Net::OAuth 0.25 or later for OAuth support" if $@;

        eval '$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A';
        die $@ if $@;

        'Net::OAuth';
    };
}

# simple check to see if we have access tokens; does not check to see if they are valid
sub authorized {
    my $self = shift;

    return defined $self->{access_token} && $self->{access_token_secret};
}

# get the athorization or authentication url
sub _get_auth_url {
    my ($self, $which_url, %params ) = @_;

    $self->_request_request_token(%params);

    my $uri = $self->$which_url;
    $uri->query_form(oauth_token => $self->request_token);
    return $uri;
}

# get the authentication URL from Twitter
sub get_authentication_url { return shift->_get_auth_url(authentication_url => @_) }

# get the authorization URL from Twitter
sub get_authorization_url { return shift->_get_auth_url(authorization_url => @_) }

# common portion of all oauth requests
sub _make_oauth_request {
    my ($self, $type, %params) = @_;

    my $request = $self->_oauth->request($type)->new(
        version          => '1.0',
        consumer_key     => $self->{consumer_key},
        consumer_secret  => $self->{consumer_secret},
        request_method   => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        nonce            => time ^ $$ ^ int(rand 2**32),
        %params,
    );

    $request->sign;

    return $request;
}

# called by get_authorization_url to obtain request tokens
sub _request_request_token {
    my ($self, %params) = @_;

    my $uri = $self->request_token_url;
    $params{callback} ||= 'oob';
    my $request = $self->_make_oauth_request(
        'request token',
        request_url => $uri,
        %params,
    );

    my $res = $self->{ua}->get($request->to_url);
    die "GET $uri failed: ".$res->status_line
        unless $res->is_success;

    # reuse $uri to extract parameters from the response content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    $self->request_token($res_param{oauth_token});
    $self->request_token_secret($res_param{oauth_token_secret});
}

# exchange request tokens for access tokens; call with (verifier => $verifier)
sub request_access_token {
    my ($self, %params ) = @_;

    my $uri = $self->access_token_url;
    my $request = $self->_make_oauth_request(
        'access token',
        request_url => $uri,
        token       => $self->request_token,
        token_secret => $self->request_token_secret,
        %params, # verifier => $verifier
    );

    my $res = $self->{ua}->get($request->to_url);
    die "GET $uri failed: ".$res->status_line
        unless $res->is_success;

    # discard request tokens, they're no longer valid
    delete $self->{request_token};
    delete $self->{request_token_secret};

    # reuse $uri to extract parameters from content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    return (
        $self->access_token($res_param{oauth_token}),
        $self->access_token_secret($res_param{oauth_token_secret}),
        $res_param{user_id},
        $res_param{screen_name},
    );
}

# exchange username and password for access tokens
sub xauth {
    my ( $self, $username, $password ) = @_;

    my $uri = $self->xauth_url;
    my $request = $self->_make_oauth_request(
        'XauthAccessToken',
        request_url     => $uri,
        x_auth_username => $username,
        x_auth_password => $password,
        x_auth_mode     => 'client_auth',
    );

    my $res = $self->{ua}->get($request->to_url);
    die "GET $uri failed: ".$res->status_line
        unless $res->is_success;

    # reuse $uri to extract parameters from content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    return (
        $self->access_token($res_param{oauth_token}),
        $self->access_token_secret($res_param{oauth_token_secret}),
        $res_param{user_id},
        $res_param{screen_name},
    );
}

# common call for both Basic Auth and OAuth
sub _authenticated_request {
    my $self = shift;

    my $authenticator = $self->{_authenticator};
    $self->$authenticator(@_);
}

sub _encode_args {
    my $args = shift;

    # Values need to be utf-8 encoded.  Because of a perl bug, exposed when
    # client code does "use utf8", keys must also be encoded.
    # see: http://www.perlmonks.org/?node_id=668987
    # and: http://perl5.git.perl.org/perl.git/commit/eaf7a4d2
    return { map { utf8::upgrade($_) unless ref($_); $_ } %$args };
}

sub _oauth_authenticated_request {
    my ($self, $http_method, $uri, $args, $authenticate) = @_;

    delete $args->{source}; # not necessary with OAuth requests

    my $is_multipart = grep { ref } %$args;

    my $msg;
    if ( $authenticate && $self->authorized ) {
        local $Net::OAuth::SKIP_UTF8_DOUBLE_ENCODE_CHECK = 1;

        my $request = $self->_make_oauth_request(
            'protected resource',
            request_url    => $uri,
            request_method => $http_method,
            token          => $self->access_token,
            token_secret   => $self->access_token_secret,
            extra_params   => $is_multipart ? {} : $args,
        );

        if ( $http_method =~ /^(?:GET|DELETE)$/ ) {
            $msg = HTTP::Request->new($http_method, $request->to_url);
        }
        elsif ( $http_method eq 'POST' ) {
            $msg = $is_multipart
                 ? POST($request->request_url,
                        Authorization => $request->to_authorization_header,
                        Content_Type  => 'form-data',
                        Content       => [ %$args ],
                   )
                 : POST($$uri, Content => $request->to_post_body)
                 ;
        }
        else {
            croak "unexpected http_method: $http_method";
        }
    }
    elsif ( $http_method eq 'GET' ) {
        $uri->query_form($args);
        $args = {};
        $msg = GET($uri);
    }
    elsif ( $http_method eq 'POST' ) {
        my $encoded_args = { %$args };
        _encode_args($encoded_args);
        $msg = $self->_mk_post_msg($uri, $args);
    }
    else {
        croak "unexpected http_method: $http_method";
    }

    return $self->{ua}->request($msg);
}

sub _basic_authenticated_request {
    my ($self, $http_method, $uri, $args, $authenticate) = @_;

    _encode_args($args);

    my $msg;
    if ( $http_method =~ /^(?:GET|DELETE)$/ ) {
        $uri->query_form($args);
        $msg = HTTP::Request->new($http_method, $uri);
    }
    elsif ( $http_method eq 'POST' ) {
        $msg = $self->_mk_post_msg($uri, $args);
    }
    else {
        croak "unexpected HTTP method: $http_method";
    }

    if ( $authenticate && $self->{username} && $self->{password} ) {
        $msg->headers->authorization_basic(@{$self}{qw/username password/});
    }

    return $self->{ua}->request($msg);
}

sub _mk_post_msg {
    my ($self, $uri, $args) = @_;

    if ( grep { ref } values %$args ) {
        # if any of the arguments are (array) refs, use form-data
        return POST($uri, Content_Type => 'form-data', Content => [ %$args ]);
    }
    else {
        # There seems to be a bug introduced by Twitter about 2013-02-25: If
        # post arguments are uri encoded exactly the same way the OAuth spec
        # requires base signature string encoding, Twitter chokes and throws a
        # 401.  This seems to be a violation of the OAuth spec on Twitter's
        # part. The specifically states the more stringent URI encoding is for
        # consistent signature generation and *only* applies to encoding the
        # base signature string and Authorization header.

        my @pairs;
        while ( my ($k, $v) = each %$args ) {
            push @pairs, join '=', map URI::Escape::uri_escape_utf8($_, '^A-Za-z0-9\-\._~'), $k, $v;
        }

        my $content = join '&', @pairs;
        return POST($uri, Content => $content);
    }
}

sub build_api_methods {
    my $class = shift;

    my $api_def_module = $class->twitter_api_def_from;
    eval "require $api_def_module" or die $@;
    my $api_def = $api_def_module->api_def;

    my $with_url_arg = sub {
        my ($path, $args) = @_;

        if ( defined(my $id = delete $args->{id}) ) {
            $path .= uri_escape($id);
        }
        else {
            chop($path);
        }
        return $path;
    };

    while ( @$api_def ) {
        my $api = shift @$api_def;
        my $api_name = shift @$api;
        my $methods = shift @$api;

        for my $method ( @$methods ) {
            my $name    = shift @$method;
            my %options = %{ shift @$method };

            my ($arg_names, $path) = @options{qw/required path/};
            $arg_names = $options{params} if @$arg_names == 0 && @{$options{params}} == 1;

            my $modify_path = $path =~ s,/id$,/, ? $with_url_arg : sub { $_[0] };

            my $code = sub {
                my $self = shift;

                # copy callers args since we may add ->{source}
                my $args = ref $_[-1] eq 'HASH' ? { %{pop @_} } : {};

                if ( (my $legacy_method = $self->can("legacy_$name")) && (
                        exists $$args{-legacy_lists_api} ? delete $$args{-legacy_lists_api}
                            : $self->{legacy_lists_api} ) ) {
                    return $self->$legacy_method(@_, $args);
                }

                # just in case it's included where it shouldn't be:
                delete $args->{-legacy_lists_api};

                croak sprintf "$name expected %d args", scalar @$arg_names if @_ > @$arg_names;

                # promote positional args to named args
                for ( my $i = 0; @_; ++$i ) {
                    my $param = $arg_names->[$i];
                    croak "duplicate param $param: both positional and named"
                        if exists $args->{$param};

                    $args->{$param} = shift;
                }

                $args->{source} ||= $self->{source} if $options{add_source};

                my $authenticate = exists $args->{authenticate}  ? delete $args->{authenticate}
                                 : $options{authenticate}
                                 ;
                # promote boolean parameters
                for my $boolean_arg ( @{ $options{booleans} } ) {
                    if ( exists $args->{$boolean_arg} ) {
                        next if $args->{$boolean_arg} =~ /^true|false$/;
                        $args->{$boolean_arg} = $args->{$boolean_arg} ? 'true' : 'false';
                    }
                }

                # Workaround Twitter bug: any value passed for skip_user is treated as true.
                # The only way to get 'false' is to not pass the skip_user at all.
                delete $args->{skip_user} if exists $args->{skip_user} && $args->{skip_user} eq 'false';

                # replace placeholder arguments
                my $local_path = $path;
                $local_path =~ s,/:id$,, unless exists $args->{id}; # remove optional trailing id
                $local_path =~ s/:(\w+)/delete $args->{$1} or croak "required arg '$1' missing"/eg;

                # stringify lists
                for ( qw/screen_name user_id/ ) {
                    $args->{$_} = join(',' => @{ $args->{$_} }) if ref $args->{$_} eq 'ARRAY';
                }

                my $uri = URI->new($self->{$options{base_url_method}} . "/$local_path.json");

                return $self->_parse_result(
                    $self->_authenticated_request($options{method}, $uri, $args, $authenticate)
                );
            };

            no strict 'refs';
            $name = $_, *{"$class\::$_"} = $code for $name, @{$options{aliases}};
        }
    }

    # catch expected error and promote it to an undef
    for ( qw/list_members is_list_member list_subscribers is_list_subscriber
            legacy_list_members legacy_is_list_member legacy_list_subscribers legacy_is_list_subscriber/ ) {
        my $orig = $class->can($_) or next;

        my $code = sub {
            my $r = eval { $orig->(@_) };
            if ( $@ ) {
                return if $@ =~ /The specified user is not a (?:memb|subscrib)er of this list/;

                die $@;
            }

            return $r;
        };

        no strict 'refs';
        no warnings 'redefine';
        *{"$class\::$_"} = $code;
    }

    # OAuth token accessors
    for my $method ( qw/
                access_token
                access_token_secret
                request_token
                request_token_secret
            / ) {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift;

            $self->{$method} = shift if @_;
            return $self->{$method};
        };
    }

    # OAuth url accessors
    for my $method ( qw/
                request_token_url
                authentication_url
                authorization_url
                access_token_url
                xauth_url
            / ) {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift;

            $self->{oauth_urls}{$method} = shift if @_;
            return URI->new($self->{oauth_urls}{$method});
        };
    }

}

sub _from_json {
    my ($self, $json) = @_;

    return eval { $json_handler->decode($json) };
}

sub _parse_result {
    my ($self, $res) = @_;

    # workaround for Laconica API returning bools as strings
    # (Fixed in Laconi.ca 0.7.4)
    my $content = $res->content;
    $content =~ s/^"(true|false)"$/$1/;

    my $obj = $self->_from_json($content);

    # Twitter sometimes returns an error with status code 200
    if ( $obj && ref $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Lite::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && defined $obj;

    my $error = Net::Twitter::Lite::Error->new(http_response => $res);
    $error->twitter_error($obj) if ref $obj;

    die $error;
}

1;
