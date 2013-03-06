#!perl
use warnings;
use strict;
use Test::More;
use Encode qw/decode encode_utf8 decode_utf8/;
use Net::Twitter::Lite;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

plan tests => 9;

my $req;
my $ua = LWP::UserAgent->new;
$ua->add_handler(request_send => sub {
    $req = shift;
    return HTTP::Response->new(200);
});

sub raw_sent_status {
    my $uri = URI->new;
    $uri->query($req->content);
    my %params = $uri->query_form;
    return $params{status};
}

sub sent_status { decode_utf8 raw_sent_status() }

my $nt = Net::Twitter::Lite->new(
    username         => 'key',
    password         => 'secret',
    ua               => $ua,
    legacy_lists_api => 0,
);
$nt->access_token('token');
$nt->access_token_secret('secret');

# "Hello world!" in traditional Chinese if Google translate is correct
my $status = "\x{4E16}\x{754C}\x{60A8}\x{597D}\x{FF01}";

ok utf8::is_utf8($status), 'status parameter is decoded';

eval { $nt->update($status) };

is sent_status(), $status, 'sent status matches update parameter';

# ISO-8859-1
my $latin1 = "\xabHello, world\xbb";

ok !utf8::is_utf8($latin1), "latin-1 string is not utf8 internally";
eval { $nt->update($latin1) };
is sent_status(), $latin1, "latin-1 matches";
ok !utf8::is_utf8($latin1), "latin-1 not promoted to utf8";

### Net::Twitter expects decoded characters, not encoded bytes
### So, sending encoded utf8 to Net::Twitter will result in double
### encoded data.

SKIP: {
    eval "use Encode::DoubleEncodedUTF8";
    skip "requires Encode::DoubleEncodedUTF8", 2 if $@;

    eval { $nt->update(encode_utf8 $status) };

    my $bytes = raw_sent_status();

    isnt $bytes, encode_utf8($status), "encoded status does not match";
    is   decode('utf-8-de', $bytes), $status, "double encoded";
};

############################################################
# Basic Auth
############################################################

$nt = Net::Twitter::Lite->new(
    username => 'fred',
    password => 'pebbles',
    ua       => $ua,
    legacy_lists_api => 0,
);

eval { $nt->update($status) };
is sent_status(), $status, 'basic auth';

eval { $nt->update($latin1) };
is sent_status(), $latin1, 'latin-1 basic auth';
