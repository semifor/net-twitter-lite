#!/usr/bin/perl
use warnings;
use strict;

use Net::Twitter::Core;
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

    my $class = "Net::Twitter::Role::API::$api";
    eval "use $class";

    my $method_map = $class->meta->get_method_map;

    return
        sort { $a->{name} cmp $b->{name} }
        grep { blessed $_ && $_->isa('Net::Twitter::Meta::Method') }
        values %$method_map;
} 

sub get_base_url_for {
    my $api = shift;

    my $class = "Net::Twitter::Role::API::$api";
    my $nt    = Net::Twitter::Core->new_with_traits(traits => ["API::$api"]);

    return $class->_base_url($nt);
}

