#!/usr/bin/perl
# perl bot.pl datafile username [number [tmpdir]]
# 'datafile' should be tab-separated mbid-url pairs
# 'username' is the MusicBrainz username to use (will prompt for password)
# 'number' is how many (max) pieces to upload in a given run (default: 2)
# 'tmpdir' is a temporary directory (default: "/tmp/")

use CoverArtBot;
use LWP::Simple;

my $file = shift @ARGV or die "You must provide a data file";
my $username = shift @ARGV or die "You must provide a username";
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

system "stty -echo";
print "Password for $username:";
my $password = <>;
system "stty echo";
print "\n";

my $bot = CoverArtBot->new($username, $password);

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
