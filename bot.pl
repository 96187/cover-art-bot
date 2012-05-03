#!/usr/bin/perl
# perl bot.pl datafile [number [tmpdir]]
# 'datafile' should be tab-separated mbid-url pairs
# 'number' is how many (max) pieces to upload in a given run (default: 2)
# 'tmpdir' is a temporary directory (default: "/tmp/")

use CoverArtBot;
use LWP::Simple;

my $file = shift @ARGV or die "You must provide a data file";
my $max = shift @ARGV || 2;
my $tmpdir = shift @ARGV || "/tmp/";

my %mbids = ();

open FILE, $file or die "Couldn't open the data file";
while (<FILE>) {
	chomp;
	my ($mbid, $url) = split /\t/;
	$mbids{$mbid} = $url;
}
close FILE;

my $bot = new CoverArtBot;

for my $mbid (keys %mbids) {
	last unless $max > 0;

	my $filename = fetch_image($mbids{$mbid});
	if (!$filename) {
		print "Failed to fetch $mbids{$mbid}.\n";
		next;
	}

	my $rv = $bot->run($mbid, $filename);
	$max--;
}

sub fetch_image {
	my $url = shift;

	return 0 unless $url =~ /\/([^\/]+)$/;
	my $filename = $tmpdir.$1;
	my $r = getstore($url, "$filename");
	print "$r\n";
	return 0 unless $r == "200";

	return $filename;
}
