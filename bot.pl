#!/usr/bin/perl
# perl bot.pl [options] datafile username
# 'datafile' is a tab-separated file. See the README for more information
# 'username' is the MusicBrainz username to use (will prompt for password)
# Options:
# -n --note: edit note to use
# -m --max: how many (max) pieces to upload in a given run (default: 2)
# -t --tmpdir: a temporary directory (default: "/tmp/")
# -p --password: password (if not provided, will prompt)
# -r --remove-note: edit note to use when removing a relationship
# -v --verbose: be chatty (default: not very talkative)

use FindBin;
use lib "$FindBin::Bin";

use CoverArtBot;
use LWP::Simple;
use Getopt::Long;

my $note = "";
my $max = 2;
my $tmpdir = "/tmp/";
my $password = '';
my $remove_note = "";
my $verbose = 0;
GetOptions('note|n=s' => \$note, 'max|m=i' => \$max, 'tmpdir|t=s' => \$tmpdir, 'password|p=s' => \$password, 'remove-note|r=s' => \$remove_note, 'verbose|v' => \$verbose);

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

my $bot = CoverArtBot->new({username => $username, password => $password, note => $note, remove_note => $remove_note, verbose => $verbose});

for my $l (@mbids) {
	unless ($max > 0) {
		print "Reached maximum number of files.\n";
		last;
	}

	my $filename = -e $l->{'url'} ? $l->{'url'} : fetch_image($l->{'url'});
	if (!$filename) {
		print STDERR "Failed to fetch $l->{$url}.\n";
		next;
	}

	my $rv = $bot->run($l, $filename);
	$max--;
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
