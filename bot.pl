#!/usr/bin/perl
# perl bot.pl [options] datafile username
# 'datafile' should be tab-separated mbid-url pairs. If you want to remove old relationships too, add a third column with l_release_url.id
# 'username' is the MusicBrainz username to use (will prompt for password)
# Options:
# -n --note: edit note to use (default 'from existing cover art relationship')
# -m --max: how many (max) pieces to upload in a given run (default: 2)
# -t --tmpdir: a temporary directory (default: "/tmp/")
# -p --password: password (if not provided, will prompt)
# -r --remove-note: edit note to use when removing a relationship (default 'cover added to cover art archive')
# -l --local: files are local, not urls (default: not local)

use CoverArtBot;
use LWP::Simple;
use Getopt::Long;

my $note = "from existing cover art relationship";
my $max = 2;
my $tmpdir = "/tmp/";
my $password = '';
my $remove_note = "cover added to cover art archive";
my $local = 0;
GetOptions('note|n=s' => \$note, 'max|m=i' => \$max, 'tmpdir|t=s' => \$tmpdir, 'password|p=s' => \$password, 'remove-note|r=s' => \$remove_note, 'local|l' => \$local);

my $file = shift @ARGV or die "Must provide a filename";
my $username = shift @ARGV or die "Must provide a username";
my @mbids = ();

open FILE, $file or die "Couldn't open the data file ($file)";
while (<FILE>) {
	chomp;
	my ($mbid, $url, $rel, $types, $comment) = split /\t/;
	push @mbids, { 'mbid' => $mbid, 'url' => $url, 'rel' => $rel, 'types' => $types, 'comment' => $comment };
}
close FILE;

if (!$password) {
	system "stty -echo";
	print "Password for $username:";
	$password = <>;
	system "stty echo";
	print "\n";
}

my $bot = CoverArtBot->new({username => $username, password => $password, note => $note, remove_note => $remove_note});

for my $l (@mbids) {
	last unless $max > 0;

	my $filename = $local ? $l->{'url'} : fetch_image($l->{'url'});
	if (!$filename) {
		print "Failed to fetch $l->{$url}.\n";
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
	print "$r\n";
	return 0 unless $r == "200";

	return $filename;
}
