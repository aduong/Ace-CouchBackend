package Ace::Couch::Sock;

use strict;
use warnings;
use parent 'Ace::Couch';
use JSON::XS;
use URI::Escape;
use IO::Socket::INET;

sub connect {
    my $class = shift;
    my $self = $class->SUPER::connect(@_);

    # hard code everything for now as POC

    $self->{couch}->{sock} = IO::Socket::INET->new(
        Proto => 'tcp',
        PeerAddr => 'localhost',
        PeerPort => 2021,
    ) or die $@;

    return $self,
};

sub _get_obj {
    my ($self, $class, $name) = @_;
    return unless defined $class && defined $name;

    my $couch = $self->{couch};
    my $sock = $couch->{sock};
    my $id = uri_escape(uri_escape("${class}_${name}"));

    print $sock $id, "\n";

    my $content = eval { decode_json(scalar <$sock>) };
    if (!defined $content) {
        # malformed JSON ? request not completed?
        $self->error($@);
        return;
    }
    elsif ($content->{error}) {
        my $error = "CouchDB error: $content->{error}";
        $error .= ", $content->{reason}" if $content->{reason};
        $self->error($error);
        return;
    }
    # in the above situations, try again?

    my $obj = $couch->{serializer}->deserialize($content->{doc}{Body}, $self)
        or die "Object could not be fetched/deserialized";


    return $obj;
}

1;

