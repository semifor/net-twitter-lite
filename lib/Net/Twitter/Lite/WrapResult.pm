package Net::Twitter::Lite::WrapResult;

=head1 NAME

Net::Twitter::Lite::WrapResult - Wrap the HTTP response and Twitter result

=head1 SYNOPSIS

    use Net::Twitter::Lite::WithAPIv1_1;

    my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        access_token        => $access_token,
        access_token_secret => $access_token_secret,
        wrap_result         => 1,
    );

    my $r = $nt->verify_credentials;

    my $http_response        = $r->http_response;
    my $twitter_result       = $r->result;
    my $rate_limit_remaining = $r->rate_limit_remaining;

=head1 DESCRIPTION

Often, the result of a Twitter API call, inflated from the JSON body of the
HTTP response does not contain all the information you need. Twitter includes
meta data, such as rate limiting information, in HTTP response headers. This
object wraps both the inflated Twitter result and the HTTP response giving the
caller full access to all the meta data. It also provides accessors for the
rate limit information.

=head1 METHODS

=over 4

=item new($twitter_result, $http_response)

Constructs an object wrapping the Twitter result and HTTP response.

=cut

sub new {
    my ( $class, $twitter_result, $http_response ) = @_;

    return bless {
        result => $twitter_result,
        http_response => $http_response,
    }, ref $class || $class;
}

=item result

Returns the inflated Twitter API result.

=item http_response

Returns the L<HTTP::Response> object for the API call.

=cut

# private method
my $limit = sub {
    my ( $self, $which ) = @_;
    
    my $res = $self->http_response;
    $res->header("X-Rate-Limit-$which") || $res->header("X-FeatureRateLimit-$which");
};

=item rate_limit

Returns the rate limit, per 15 minute window, for the API endpoint called.
Returns undef if no suitable rate limit header is available.

=cut

sub rate_limit           { shift->$limit('Limit') }

=item rate_limit_remaning

Returns the calls remaining in the current 15 minute window for the API
endpoint called.  Returns undef if no suitable header is available.

=cut

sub rate_limit_remaining { shift->$limit('Remaining') }

=item rate_limit_reset

Returns the unix epoch time time of the next 15 minute window, i.e., when the
rate limit will be reset, for the API endpoint called.  Returns undef if no
suitable header is available.

=cut

sub rate_limit_reset     { shift->$limit('Reset') }

use strict;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors(simple => qw/result http_response/);

1;

__END__

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Marc Mims <marc@questright.com>

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

