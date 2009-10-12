#!/usr/bin/perl
use warnings;
use strict;

use Net::Twitter;
use Template;

my ($version, $input, $output) = @ARGV;

my $tt = Template->new;
$tt->process($input, {
        VERSION          => $version,
        get_methods_for  => \&get_methods_for,
        get_base_url_for => \&get_base_url_for,
    },
    $output,
) || die $tt->error;

sub get_methods_for {
    my $api = shift;

    my $nt = Net::Twitter->new(traits => [ "API::$api" ]);

    return
        sort { $a->{name} cmp $b->{name} }
        grep { blessed $_ && $_->isa('Net::Twitter::Meta::Method') }
             $nt->meta->get_all_methods;
} 

sub get_base_url_for {
    my $api = shift;

    my $class = "Net::Twitter::Role::API::$api";
    my $nt    = Net::Twitter::Core->new_with_traits(traits => ["API::$api"]);

    return $class->_base_url($nt);
}
