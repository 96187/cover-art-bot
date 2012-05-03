#!/usr/bin/perl
# perl bot.pl datafile
# datafile should be tab-separated mbid-url pairs

use CoverArtBot;
use LWP::Simple;

my $max = 2;
my $tmpdir = "/tmp/";

my %mbids = ();
my $file = shift @ARGV or die;
open FILE, $file or die;
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