package Net::Twitter::Lite::OAuth;
use warnings;
use strict;

use base qw/Net::OAuth::Simple/;

=head1 NAME

Net::Twitter::Lite::OAuth - A Twitter specific subclass of Net::OAuth::Simple

=head1 DESCRIPTION

This is a simple sub-class of C<Net::OAuth::Simple> providing an overridden
C<request_access_token> method which accepts an option PIN number parameter for
use in Twitter desktop applications.

=head1 METHODS

=over 4

=item new

Accepts the same arguments as C<Net::OAuth::Simple> with an additional, optional, C<useragent>
argument.  If provided, the C<useragent> should be a C<LWP::UserAgent> or C<LWP::UserAgent>
derived class.  If not provided, an C<LWP::UserAgent> instance will be created.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $useragent = delete $args{useragent};

    my $new = $class->SUPER::new(%args);
    $new->{browser} = $useragent if $useragent;

    return $new;
}

=item request_access_token [PIN]

Request the access token and access token secret for this user.

The user must have authorized this app at the url given by C<get_authorization_url> first.

For desktop applications, the Twitter authorization page will present the user
with a PIN number.  Prompt the user for the PIN number, and pass it as an
argument to request_access_token.

Returns the access token and access token secret but also sets them internally
so that after calling this method, you can immediately call API methods
requiring authentication.

=cut

sub request_access_token {
    my $self = shift;
    my $pin  = shift;

    my $url  = $self->access_token_url;
    my $response = $self->_make_request(
        'Net::Twitter::Lite::AccessTokenRequest',
        $url, 'GET',
        token            => $self->request_token,
        token_secret     => $self->request_token_secret,
        $pin ? ( verifier => $pin ) : (),
    );

    my $uri = URI->new;
    $uri->query($response->content);
    my %param = $uri->query_form;

    # Split out token and secret parameters from the access token response
    $self->access_token($param{oauth_token});
    $self->access_token_secret($param{oauth_token_secret});

    delete $self->{tokens}->{$_} for qw(request_token request_token_secret);

    die "ERROR: $url did not reply with an access token"
      unless ( $self->access_token && $self->access_token_secret );

    return ( $self->access_token, $self->access_token_secret );
}

# Just a copy of Net::OAuth::AccessTokenRequest with optional message param "verifier" added
package Net::Twitter::Lite::AccessTokenRequest;
use warnings;
use strict;
use base 'Net::OAuth::Request';

__PACKAGE__->add_required_message_params(qw/token/);
__PACKAGE__->add_optional_message_params(qw/verifier/);
__PACKAGE__->add_required_api_params(qw/token_secret/);
sub allow_extra_params {0}
sub sign_message {1}

1;

=back

=head1 SEE ALSO

L<Net::Twitter::Lite>, L<Net::OAuth::Simple>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
