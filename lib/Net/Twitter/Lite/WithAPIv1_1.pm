package Net::Twitter::Lite::WithAPIv1_1;
use warnings;
use strict;
use parent 'Net::Twitter::Lite';

=head1 NAME

Net::Twitter::Lite::WithAPIv1_1 - A perl API library for Twitter's API v1.1

=cut

sub twitter_api_def_from           () { 'Net::Twitter::Lite::API::V1_1' }
sub _default_api_url               () { 'http://api.twitter.com/1.1'    }
sub _default_searchapiurl          () { 'http://search.twitter.com'     }
sub _default_search_trends_api_url () { 'http://api.twitter.com/1.1'    }
sub _default_lists_api_url         () { 'http://api.twitter.com/1.1'    }

sub new {
    my $class = shift;
    my %options = @_;

    # Twitter now requires SSL connections. Since Net::Twitter::Lite is used
    # for Twitter API compatible services that may not require, or indeed allow
    # SSL, we won't change the default, yet. We'll have a deprecation cycle
    # where we warn users if they don't have an ssl option set and let them
    # know enabling ssl will be the default in the future.
    unless ( exists $options{ssl} ) {
        warn <<'';
The Twitter API now requires SSL. Add ( ssl => 1 ) to the options passed to new
to enable it.  For backwards compatibility, SSL is disabled by default in this
version. Passing the ssl option to new will disable this warning. If you are
using a Twitter API compatbile service that does not support SSL, add
( ssl => 0 ) to disable this warning and preserve non-SSL connections in future
upgrades.

        $options{ssl} = 0;
    }


    return $class->SUPER::new(legacy_lists_api => 0, %options);
}

1;
