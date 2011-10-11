package Sordid::CGI;

use Template::Alloy;
use File::Basename 'fileparse';
use base Exporter;
our @EXPORT_OK = qw/%_GET %_POST/;
#our @EXPORT_OK = qw( %_GET %_POST );
=head1 NAME

Sordid::CGI - Rapid, Simple CGI application development

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

*NOTE* Please be aware that as of 0.5 I will be giving Sordid::CGI a complete revamp. The _GET, _POST 
and _SESSION hashes will be diminished and replaced by something nicer and less PHPish.

Sordid::CGI can be used to create quick (and dirty) CGI applications. While I recommend 
the use of awesome frameworks that can use FastCGI, like Catalyst, sometimes you want 
to just write out some quick Perl code, instead of learning an entire framework. A 
working example of a simple query string.

    ## index.pl
    #!/usr/bin/env perl

    # don't forget to import %_GET, %_POST or both depending on what you need
    use Sordid::CGI qw( %_GET );

    my $s = Sordid::CGI->new(view => 'default.tt');
    
    $s->stash(title => "The I like to Greet Page!");

    if (exists $_GET{name}) {
        $s->stash(name => $_GET{name});
    }
    else {
        $s->stash(name => 'Anonymous');
    }

    $s->process('greet.tt');

    ## view/default.tt
    
    <!doctype html><html><head><title><% title %></title></head>
    <body>
        <% content %>
    </body>
    </html>

    ## template/greet.tt
    
    Hello there, <% name %>!
=cut
    
our %_GET = ();
our %_POST = ();

=head2 Sordid::CGI->new

Creates a new instance of Sordid::CGI and also detects whether 
GET or POST has been submitted, then adds the values into %_GET and 
%_POST respectively.

=cut

sub new {
    my ($class, %args) = @_;
    $self = {
        template_path => 'template'||$args{template_path},
        wrapper => $args{view}||undef
    };

    $self->{stash} = {};

    if (defined $args{config}) {
        print "Getting config\n";
        our $config = {};
        do "$args{config}";
        $self->{c} = \%$config;
    }
    my $method = $ENV{'REQUEST_METHOD'}; 
    my $qs = (exists $ENV{'QUERY_STRING'}) ? $ENV{'QUERY_STRING'} : undef;
    __PACKAGE__->do_GET($qs) if ($qs);
    __PACKAGE__->do_POST if (defined $method && $method eq 'POST');
    bless $self, $class;
    return $self;
}

sub stash {
    my ($self, %a) = @_;
    for (keys %a) {
        $self->{stash}->{$_} = $a{$_};
    }
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

sub include {
    my ($self, $template) = @_;

    require $self->{template_path} . '/' . $template . '.pl';
}

sub view {
    my ($self, $v) = @_;

    $self->{stash}->{template}->process(
        "$v.tt",
        $self->{stash}
    );
}

=head2 process

Processes the template. If no argument is passed then the template will be 
$self->{$template_path}/<filename>.tt

    $s->process;
    $s->process('about.tt');

=cut

sub process {
    my ($self, $temp, $var) = @_;
    use FindBin;
    print "Content-Type: text/html; charset: utf-8;\n\n";    
    $self->{stash}->{tt} = Template::Alloy->new(
            INCLUDE_PATH => [$self->{template_path}, "$FindBin::Bin"],
            WRAPPER      => "view/$self->{wrapper}"||undef,
            START_TAG => quotemeta('<%'),
            END_TAG   => quotemeta('%>'),
    );
    my $fname = $0;
    my ($name, $path, $suffix) = fileparse($fname, '\.[^\.]*');
    $self->{stash}->{tt}->process($temp||$name . '.tt', $self->{stash}, $var||undef);
}

1;

