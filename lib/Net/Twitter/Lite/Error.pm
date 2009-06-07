package Net::Twitter::Lite::Error;
use warnings;
use strict;

use overload '""' => \&error;

# This is basically a duplicate of Net::Twitter::Lite::Error, only without Moose.  I
# considered creating a new Net-Twitter-Error distribution so that it could be
# shared by both Net::Twitter and Net::Twitter::Lite.  But there's a strong
# argument for making Net::Twitter::Lite depend upon as few modules as
# possible.

=head1 NAME

Net::Twitter::Lite::Error - Encapsulates errors thrown by Net::Twitter::Lite

=head1 SYNOPSIS

  use Net::Twitter::Lite;
  my $nt = Net::Twitter::Lite->new;
  my $r = eval { $nt->friends_timeline };
  warn "$@\n" if $@;

=head1 DESCRIPTION

B<Net::Twitter::Lite::Error> encapsulates errors thrown by C<Net::Twitter::Lite>.  A
C<Net::Twitter::Lite::Error> object will contain an C<HTTP::Response>, and a HASHREF
containing Twitter API error information if one was returned by Twitter.

=head1 METHODS

=over 4

=cut

=item new

Constructs an C<Net::Twitter::Lite::Error> object with an HTTP::Response and optionally
a Twitter error HASH ref.  It takes HASH of arguments.  Examples:

  my $e = Net::Twitter::Lite::Error->new(http_response => $res, twitter_error => $te);
  my $e = Net::Twitter::Lite::Error->new(http_response => $res);

=cut

sub new {
    my ($class, %args) = @_;

    return bless \%args, $class;
}

=item twitter_error

Get or set the encapsulated Twitter API error HASH ref.

=cut

sub twitter_error {
    my $self = shift;

    $self->{twitter_error} = shift if @_;

    return $self->{twitter_error};
}

=item http_response

Get or set the encapsulated HTTP::Response instance.

=cut

sub http_response {
    my $self = shift;

    $self->{http_response} = shift if @_;

    return $self->{http_response};
}

=item code

Returns the HTTP Status Code from the encapsulated HTTP::Response

=cut

sub code {
    my $self = shift;

    return exists $self->{http_response} && $self->{http_response}->code;
}

=item message

Returns the HTTP Status Message from the encapsulated HTTP::Response

=cut

sub message {
    my $self = shift;

    return exists $self->{http_reponse} && $self->{http_response}->message;
}

=item error

Returns an error message as a string.  The message be the C<error> element of
the encapsulated Twitter API HASH ref, if there is one.  Otherwise it will
return a string containing the HTTP Status Code and Message.  If the
C<Net::Twitter::Lite::Error> instance does not contain either an HTTP::Response or a
Twitter Error HASH ref, or the HTTP::Response has no status code or message,
C<error> returns the string '[unknown]'.

A Net::Twitter::Lite::Error stringifies to the C<error> message.

=cut

sub error {
    my $self = shift;

    # We MUST stringyfy to something that evaluates to true, or testing $@ will fail!
    exists $self->{twitter_error} && $self->{twitter_error}{error}
        || ( exists $self->{http_response}
             && ($self->code . ": " . $self->message )
           )
        || '[unknown]';
}

1;

__END__

=back

=head1 SEE ALSO

L<Net::Twitter::Lite>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See L<perlartistic>.

=cut
