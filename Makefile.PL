use inc::Module::Install;

version '0.11001';

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
requires    'Memoize';

# CPAN
requires    'JSON'           => 2.02;
requires    'URI'            => 1.40;
requires    'URI::Escape';
requires    'LWP::UserAgent' => 2.032;
requires    'Crypt::SSLeay'  => 0.5;

feature 'OAuth Authentication',
    -default     => 1,
    'Net::OAuth' => '0.25',
    ;

feature '.netrc support',
    -default     => 0,
    'Net::Netrc' => 0,
    ;

no_index    directory => 'src';
no_index    directory => 'examples';

# resources
homepage   'http://github.com/semifor/Net-Twitter-Lite';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter-Lite';

auto_set_repository;
auto_manifest;
auto_install;

WriteAll;
