use inc::Module::Install;

version '0.01000';

# MAINTAINER only exists in the repository (i.e., development) version of the
# project. This eliminates the need for requireing Template and Net::Twitter.
# lib/Net/Twitter/Lite.pm is created dynamically from a TT2 template and
# introspecting Net::Twitter.  Net::Twitter is Moose based.  Net::Twitter::Lite
# provides the REST and Search API without requiring Moose.  Moose, Template,
# and Net::Twitter are only needed by the maintainer to prepare a distribution.
#
# To build lib/Net/Twitter/Lite.pm from src/net-twitter-lite.tt2: touch
# MAINTAINER then run "perl Makefile.PL"
if ( -e 'MAINTAINER' ) {
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
requires    'JSON::Any' => 1.19;
requires    'URI::Escape';
requires    'LWP::UserAgent' => 2.032;
recommends  'JSON::XS';

no_index    directory => 'src';

# resources
repository 'git://github.com/semifor/Net-Twitter-Lite.git';
homepage   'http://github.com/semifor/Net-Twitter-Lite';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter-Lite';

auto_install;

WriteAll;
