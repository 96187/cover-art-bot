#!/usr/bin/perl

package CoverArtBot;
use utf8;
use WWW::Mechanize;

sub new {
	my ($package, $username, $password) = @_;
	my %hash;
	%hash = (
		FORM => {},
		'server' => 'musicbrainz.org',
		'username' => $username,
		'password' => $password,
		'useragent' => 'cover art bot/0.1',
		'mech' => WWW::Mechanize->new(agent => $self->{'useragent'}, autocheck => 1)
	);
	bless \%hash => $package;
}

sub run {
	my ($self, $mbid, $filename) = @_;

	$self->{'mbid'} = $mbid;
	$self->{'filename'} = $filename;
	print $self->{'mbid'},"\n";
	print $self->{'filename'},"\n";

	if ($self->cover_exists) {
		print "Skipping $mbid: Already has cover art.\n";
		return 0;
	}

	if (!$self->add_cover_art) {
		print "Couldn't add cover art.\n";
		return 0;
	}

	return 1;
}

sub cover_exists {
	my ($self) = @_;
	if ($self->load_url("http://coverartarchive.org/release/".$self->{'mbid'})) {
		return 1;
	}
	
	return 0;
}

sub load_url {
	my ($self, $url, $method) = @_;
#	print "Fetching $url ...\n";
	my $browser = LWP::UserAgent->new();
	$browser->agent($self->{'useragent'});
	my $r = ($method && $method eq "post") ? $browser->post($url) : $browser->get($url);
	sleep 1;
	if ($r->is_success) {
		return $r->decoded_content;
	}
	return undef;
}

sub add_cover_art {
	my ($self) = @_;
	my $mech = $self->{'mech'};

	if (!$self->{'loggedin'}) {
		# load login page
		my $url = "http://".$self->{'server'}."/login";
		$mech->get($url);
		sleep 1;

		# submit login page
		my $r = $mech->submit_form(
			form_number => 2,
			fields => {
				username => $self->{'username'},
				password => $self->{'password'},
			}
		);
		$self->{'loggedin'} = 1;
		sleep 1;
	}

	# find iframe
	my $url = "http://".$self->{'server'}."/release/".$self->{'mbid'}."/add-cover-art";
	$mech->get($url);
	my $iframe = $mech->find_link(tag => 'iframe');

	# load iframe
	my $mech2 = $mech->clone();
	$mech2->get( $iframe->url() );

	# upload image
	$mech2->field("file", $self->{'filename'});
	$mech2->submit();
	if ($mech2->content !~ /parent.document.getElementById/) {
		print "Error uploading image.\n";
		return 0;
	}

	sleep 2;

	# submit edit	
	$mech->form_id("add-cover-art");
	$mech->select("add-cover-art.type_id", "1");
	$mech->untick("add-cover-art.as_auto_editor", "1");
	$mech->field("add-cover-art.edit_note", "from existing cover art relationship");
	$mech->submit();

	print $mech->uri, "\n";
	return $mech->uri;
}

1;
