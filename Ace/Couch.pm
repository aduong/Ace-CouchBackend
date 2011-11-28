package Ace::Couch;

use strict;
use warnings;
use parent 'Ace';
use JSON;
use URI::Escape;
use Carp qw(croak);
use LWP::UserAgent;
use Ace::Object;

sub connect { # only supports multi-arg form
    my $class = shift;
    my $self = $class->SUPER::connect(@_) or die;

    my %args = @_;
    my $couch = $args{-couch} // {};

    $couch->{host}       //= 'localhost';
    $couch->{port}       //= 5984;
    $couch->{db}         //= $couch->{database} // 'ace';
    $couch->{serializer} //= 'Ace::Couch::jace' ;

    $self->{couch} = $couch;
    $self->{agent} = LWP::UserAgent->new(
        agent      => 'WormBase2-Couch/1.0',
        keep_alive => 10,
    );

    return $self;
}

sub fetch {
    my ($self, %args) = @_;
    goto &Ace::fetch unless defined $args{-class} && $args{-name};

    return $self->get($args{-class}, $args{-name},
                      $args{-fill} || $args{-filled} || $args{-filltag});
}

sub get {
    my ($self, $class, $name, $fill) = @_;

    die "Problem. No class or name provided."
       unless defined $class && defined $name;

    my $obj = $self->memory_cache_fetch($class => $name)
           || $self->file_cache_fetch($class => $name);

    return $obj if $obj;

    # get from Couch first if can't find in mem/file cache
    if ($obj = $self->_get_obj($class => $name)) {
        # cache it
        $self->memory_cache_store($obj);
        $self->file_cache_store($obj);

        return $obj;
    }
    else {
        warn $self->error;
    }

    # Ace.pm fallback (will handle caching as well)
    return $self->_acedb_get($class, $name, $fill);
}

sub _get_obj {
    my ($self, $class, $name) = @_;
    return unless defined $class && defined $name;

    my $couch = $self->{couch};
    my $url = "http://$couch->{host}:$couch->{port}/$couch->{db}/"
            . uri_escape(uri_escape("${class}_${name}"));

    my $res = $self->{agent}->get($url);
    if (!$res->is_success) {
        $self->error('HTTP error ' . $url . ':' . $res->status_line);
        return;
    }

    my $content = eval { decode_json($res->content) };
    if (!defined $content) {
        $self->error('JSON decode error: ' . $@);
        return;
    }
    elsif ($content->{error}) {
        $self->error("CouchDB error: $content->{error}, $content->{reason}");
        return;
    }

    my $obj = $couch->{serializer}->deserialize($content->{Body}, $self)
        or $self->error('Could not deserialize object');

    return $obj;
}

package Ace::Couch::jace;

sub new {
    return __PACKAGE__;
}

sub serialize {
    die "Not a real serializer!\n";
}

sub deserialize {
    my $self = shift;
    return Ace::Object->newFromText(@_);
}

1;
