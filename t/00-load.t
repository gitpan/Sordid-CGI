#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Sordid::CGI' ) || print "Bail out!\n";
    use_ok( 'Sordid::CGI::Session' ) || print "Bail out!\n";
}

diag( "Testing Sordid::CGI $Sordid::CGI::VERSION, Perl $], $^X" );
