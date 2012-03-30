#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Twitter::Lite' );
}

diag( "Testing Net::Twitter::Lite $Net::Twitter::Lite::VERSION, Perl $], $^X" );
