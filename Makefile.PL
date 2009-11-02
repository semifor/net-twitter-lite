use inc::Module::Install;

version '0.08005';

if ( $Module::Install::AUTHOR ) {
    eval "use Net::Twitter::Core";
    die $@ if $@;

    my $perl5_lib =  join ':', @INC;
    my @libs = map "-I$_", @INC;

    system($^X, @libs, "src/build.pl",
           version, 'src/net-twitter-lite.tt2', 'lib/Net/Twitter/Lite.pm')
        == 0 || die "src/bulid.pl failed: $?";

    system 'pod2text lib/Net/Twitter/Lite.pm > README';
}

name        'Net-Twitter-Lite';
all_from    'lib/Net/Twitter/Lite.pm';

# core
requires    'Carp';
requires    'Encode';

# CPAN
requires    'JSON::Any'      => '1.21';
requires    'URI'            => 1.40;
requires    'URI::Escape';
requires    'LWP::UserAgent' => 2.032;

feature 'OAuth Authentication',
    -default     => 1,
    'Net::OAuth' => '0.16',
    ;

feature '.netrc support',
    -default     => 0,
    'Net::Netrc' => 0,
    ;

# Don't rely on the JSON::Any requirement to pull in a suitable JSON backend.
# The user may already have JSON::Any installed, but since removed all valid
# providers.  (Yes, this seems to have happened in the wild.)
sub has_json_handler () {
    my @order = qw/JSON::XS JSON/;
    for my $provider ( @order ) {
        eval "require $provider";
        return 1 unless $@;
    }
    return;
}

has_json_handler || requires JSON => '2.02';

no_index    directory => 'src';
no_index    directory => 'examples';

# resources
homepage   'http://github.com/semifor/Net-Twitter-Lite';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter-Lite';

auto_set_repository;
auto_manifest;
auto_install;

WriteAll;
