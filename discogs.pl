#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use JSON;
use LWP::Simple;

die "Need a URL" unless @ARGV;

for my $url (@ARGV) {
	if ($url =~ /\/release\/([0-9a-f-]{36})/) {
		my $mbid = $1;
		my $mbjson = get("https://musicbrainz.org/ws/2/release/$mbid?fmt=json&inc=url-rels");
		if (!$mbjson) {
			print STDERR "Error parsing data from MusicBrainz.\n";
			next;
		}
		my $mbdata = from_json($mbjson);

		for my $rel (@{ $mbdata->{"relations"} }) {
			next unless $rel->{"type"} eq "discogs";

			my $count = 0;
			my $url = $rel->{"url"}->{"resource"};
			if ($url =~ /discogs\.com\/release\/([0-9]+)/) {
				my $djson = get("http://api.discogs.com/releases/$1");
				if (!$djson) {
					print STDERR "Error parsing data from MusicBrainz.\n";
					next;
				}

				my $ddata = from_json($djson);
				for my $item (@{ $ddata->{"images"} }) {
					print "$mbid\t", $item->{"uri"},"\tNone\n";
				}
				$count++;
			}
			if ($count == 0) {
				print STDERR "No usable Discogs relationship found.\n";
			}
		}
	} else {
		print STDERR "No MBID found.\n";
	}
}
