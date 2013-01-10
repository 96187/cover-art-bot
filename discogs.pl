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
		my $mbdata = from_json($mbjson);
		next unless $mbdata;

		for my $rel (@{ $mbdata->{"relations"} }) {
			next unless $rel->{"type"} eq "discogs";

			if ($rel->{"url"} =~ /discogs\.com\/release\/([0-9]+)/) {
				my $djson = get("http://api.discogs.com/releases/$1");
				next unless $djson;

				my $ddata = from_json($djson);
				for my $item (@{ $ddata->{"images"} }) {
					print "$mbid\t", $item->{"uri"},"\tNone\n";
				}
			}
		}
	}
}
