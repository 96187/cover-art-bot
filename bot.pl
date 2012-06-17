#!/usr/bin/perl
# perl bot.pl [options] datafile username
# See the README for more information

use FindBin;
use lib "$FindBin::Bin";

use CoverArtBot;
use LWP::Simple;
use Getopt::Long;

my $note = "";
my $max = 100;
my $tmpdir = "/tmp/";
my $password = '';
my $remove_note = "";
my $verbose = 0;
my $use_front = 0;
GetOptions('note|n=s' => \$note, 'max|m=i' => \$max, 'tmpdir|t=s' => \$tmpdir, 'password|p=s' => \$password, 'remove-note|r=s' => \$remove_note, 'verbose|v' => \$verbose, 'use_front|f' => \$use_front);

my $file = shift @ARGV or die "Must provide a filename";
my $username = shift @ARGV or die "Must provide a username";
my @mbids = ();

open FILE, $file or die "Couldn't open the data file ($file)";
while (<FILE>) {
	chomp;
	my ($mbid, $url, $types, $comment, $rel) = split /\t/;
	push @mbids, { 'mbid' => $mbid, 'url' => $url, 'rel' => $rel, 'types' => $types, 'comment' => $comment };
}
close FILE;

if (!$password) {
	system "stty -echo";
	print "Password for $username: ";
	$password = <>;
	system "stty echo";
	print "\n";
}

my $bot = CoverArtBot->new({username => $username, password => $password, note => $note, remove_note => $remove_note, verbose => $verbose, use_front => $use_front});

for my $l (@mbids) {
	unless ($max > 0) {
		print "Reached maximum number of files.\n";
		last;
	}

	my $precheck_ok = $bot->precheck($l);

	if ($precheck_ok) {
		my $filename = -e $l->{'url'} ? $l->{'url'} : fetch_image($l->{'url'}, $l->{'mbid'});
		if (!$filename) {
			my $urlname = $l->{'url'};
			print STDERR "Failed to fetch $urlname.\n";
			next;
		}

		my $rv = $bot->run($l, $filename);
		
		$max -= $rv;
	}

	print "$max more image(s)...\n\n";
}

sub fetch_image {
	my $url = shift;

	return 0 unless $url =~ /\/([^\/]+)$/;
	my $filename = $tmpdir.$1;
	my $r = getstore($url, "$filename");
#	print "$r\n";
	return 0 unless $r == "200";

	return $filename;
}
