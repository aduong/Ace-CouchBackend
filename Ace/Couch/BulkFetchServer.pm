package Ace::Couch::BulkFetchServer;

use strict;
use warnings;

use JSON::XS;
use IO::Socket::INET;
use Net::HTTP;
use Net::HTTP::NB;
use IO::Select;

my $CRLF = "\x0A\x0D";

my @queue;
my %requests;
my $http_busy = 0;

my $sock = IO::Socket::INET->new(
    Proto => 'tcp',
    LocalAddr => 'localhost',
    LocalPort => 2021,
    Listen   => 5,
) or die $@;

my $nbhttp;
my $select = IO::Select->new($sock);

my $err_res = encode_json({
    error => 'connection',
    reason => 'request could not be served',
});

while () {
    # prioritize distributing couch data and accepting requests.
    # send requests last. makes use of buffering better
    for my $fh ($select->can_read) {
        if ($fh == $sock) {
            my $newsock = $fh->accept;
            $select->add($newsock);
        }
        elsif (defined $nbhttp && $fh == $nbhttp) {
            my $code = $fh->read_response_headers;
            next unless $code =~ /^2/o;

            my $data = '';
            my $buf;
            while ($fh->read_entity_body($buf)) {
                $data .= $buf;
            }

            for my $result (@{decode_json($data)->{rows}}) {
                # i believe key should always be present. id is not
                # when there is no doc in couchdb.
                my $id = $result->{id} || $result->{key};
                if (!$requests{$id}) {
                    print "No requesters found for request $id\n";
                    next;
                }

                for my $out (@{$requests{$id}}) {
                    print $out encode_json($result), "\n";
                }

                delete $requests{$id};
                print "Resolved request $id\n";
            }

            # closing http connection
            $select->remove($nbhttp);
            undef $nbhttp;
            print "http_busy ", defined $nbhttp ? 1 : 0, "\n";
        }
        else {                 # just a requester sending us a request
            if (defined(my $request = <$fh>)) {
                unless ($request =~ /^[^_]+_.+\n$/) {
                    print "Problematic input: $request\n";
                    next;
                }

                chomp $request;

                if ($requests{$request}) {
                    print "duplicate unresolved request: |$request|\n";
                    push @{$requests{$request}}, $fh;
                }
                else {
                    print "adding request to queue: |$request|\n";
                    push @queue, $request;
                    $requests{$request} = [$fh];
                }
                print "http_busy ", defined $nbhttp ?  1 : 0, "\n";
            }
            else {              # closing socket
                print "shutting down socket\n";
                $select->remove($fh);
                $fh->close;
            }
        }
    }

    if (!$nbhttp and @queue) {
        print "sending off a request\n";
        $nbhttp = Net::HTTP->new(Host => 'dev.wormbase.org', PeerPort => 5984);
        $select->add($nbhttp);
        $nbhttp->write_request(
            POST => '/jace/_all_docs?include_docs=true',
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
            encode_json({ keys => \@queue }),
        );
        @queue = ();
    }
}

1; # for package... but this isn't really a package right now
