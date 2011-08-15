package Sordid::CGI;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( %_GET %_POST );
=head1 NAME

Sordid::CGI - Rapid, Simple CGI application development

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

Sordid::CGI can be used to create quick (and dirty) CGI applications. While I recommend 
the use of awesome frameworks that can use FastCGI, like Catalyst, sometimes you want 
to just write out some quick Perl code, instead of learning an entire framework. A 
working example of a simple query string.

    #!/usr/bin/env perl

    use warnings;
    use strict;

    # don't forget to import %_GET, %_POST or both depending on what you need
    use Sordid::CGI qw( %_GET );

    my $webs = Sordid::CGI->new;

    $webs->start_html; # send content-type header information

    if (exists $_GET{name}) {
        print "<p>Hello, " . $_GET{name} . "</p>\n";
    }
    else {
        print "<p>Hi Anonymous!</p>\n";
    }
=cut
    

our %_GET = ();
our %_POST = ();

=head2 Sordid::CGI->new

Creates a new instance of Sordid::CGI and also detects whether 
GET or POST has been submitted, then adds the values into %_GET and 
%_POST respectively.
=cut

sub new {
    my $class = shift;
    $self = {};
    my $qs = (exists $ENV{'QUERY_STRING'}) ? $ENV{'QUERY_STRING'} : undef;
    __PACKAGE__->do_GET($qs) if ($qs);
 
    __PACKAGE__->do_POST if (exists $ENV{REQUEST_METHOD} && $ENV{REQUEST_METHOD} eq 'POST');
    bless $self, $class;
    return $self;
}

sub do_GET {
    my ($self, $qs) = @_;
    my @res = ();
    if (index($qs, '&') != -1) {
        my @s = split('&', $qs);
        foreach (@s) {
            @res = split('=', $_);
            $_GET{$res[0]} = $self->url_decode($res[1]);
        }
    }
    else {
        @res = split('=', $qs);
        $_GET{$res[0]} = $self->url_decode($res[1]);
    }
    return;
}

sub do_POST {
    my $self = shift;
    my $ps;
    read( STDIN, $ps, ($ENV{'CONTENT_LENGTH'}||155) );
    if (length $ps > 0) {
        my @res = ();
        if (index($ps, '&') != -1) {
            my @s = split('&', $ps);
            foreach (@s) {
                @res = split('=', $_);
                $_POST{$res[0]} = $self->url_decode($res[1]);
            }
        }
        else {
            @res = split('=', $ps);
            $_POST{$res[0]} = $self->url_decode($res[1]);
        }
    }
    return;
}

=head2 Sordid::CGI->start_html
Prints the content type to the browser. Things like redirects MUST 
be written BEFORE you start_html

    use Sordid::CGI qw( %_POST );
    
    my $webs = Sordid::CGI->new;

    if (! exists($_POST{'submit_login'})) {
        $webs->redirect('/cgi-bin/login.pl');
    }

    $webs->start_html; # prints similar to Content-Type: text/html\n\n

    print qq{ <p>Hello, World!</p> };
=cut

sub start_html {
    print "Content-Type: text/html\r\n\r\n";
}

=head2 Sordid::CGI->redirect

Redirects the user to a different page. Redirects need to be 
done before the main html stuff (before start_html)

    Sordid::CGI->redirect('/uri/to/redirect/to');

=cut

sub redirect {
    my $self = shift;
    my $uri = shift;
    my $time = shift||0;
    print "Refresh: $time; url=$uri\r\n";
    print "Content-type: text/html\r\n";
    print "\r\n";
    exit;
}

# Reference: http://glennf.com/writing/hexadecimal.url.encoding.html
=head2 Sordid::CGI->url_decode

Turns all of the weird HTML characters into human readable stuff. This is 
automatically called when you get POST or GET data
=cut

sub url_decode {
    my ($self, $string) = @_;
    $string =~ tr/+/ /;
    $string =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $string =~ s/<!--(.|\n)*-->//g;
    return $string;
}

=head2 Sordid::CGI->url_encode

This works the same as url_decode, except around the other way.
=cut

sub url_encode {
    my ($self, $string) = @_;
    my $MetaChars = quotemeta( ';,/?\|=+)(*&^%$#@!~`:');
    $string =~ s/([$MetaChars\"\'\x80-\xFF])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
    $string =~ s/ /\+/g;
    return $string;
}
1;

