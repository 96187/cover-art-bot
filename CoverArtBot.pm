#!/usr/bin/perl

package CoverArtBot;
use utf8;
use WWW::Mechanize;

sub new {
	my ($package, $args) = @_;
	my %hash;
	%hash = (
		FORM => {},
		'server' => 'musicbrainz.org',
		'username' => $args->{username},
		'password' => $args->{password},
		'use_front' => $args->{use_front} || 0,
		'useragent' => 'cover art bot/0.1',
		'note' => $args->{note} || "",
		'remove_note' => $args->{remove_note} || "",
		'verbose' => $args->{verbose},
		'mech' => WWW::Mechanize->new(agent => $self->{'useragent'}, autocheck => 1),
		'releases' => ()
	);
	bless \%hash => $package;
}

sub precheck {
	my ($self, $l) = @_;

	$self->{'mbid'} = $l->{'mbid'};
	$self->{'rel'} = $l->{'rel'};
	$self->{'types'} = $l->{'types'} || "Front";
	$self->{'comment'} = $l->{'comment'};

	return 1 if $self->{'precheck'}->{ $self->{'mbid'} };

	print "MBID: ".$self->{'mbid'}."\n" if $self->{'verbose'};
	print "Types: ".$self->{'types'}."\n" if $self->{'verbose'};
	print "Comment: ".$self->{'comment'}."\n" if $self->{'verbose'};
	print "Relationship ID: ".$self->{'rel'}."\n" if $self->{'verbose'};

	if ($self->cover_exists) {
		print STDERR "Skipping ".$self->{'mbid'}.": Already has cover art.\n";
		my $mbid = $self->{'mbid'};
		return 0;
	}

	$self->{'precheck'}->{ $self->{'mbid'} } = 1;

	return 1;
}

sub run {
	my ($self, $l, $filename) = @_;

	if (!$self->precheck($l)) {
		return 0;
	}

	$self->{'filename'} = $filename;
	print "Filename: ".$self->{'filename'}."\n" if $self->{'verbose'};

	print "pre-checking complete, uploading...\n" if $self->{'verbose'};

	if (!$self->add_cover_art) {
		print STDERR "Couldn't add cover art.\n";
		return 0;
	}

	if ($self->{'rel'} && !$self->remove_relationship()) {
		print STDERR "Couldn't remove relationship ".$self->{'rel'}.".\n";
		return 0;
	}

	return 1;
}

sub cover_exists {
	my ($self) = @_;

	return 0 if $self->{'releases'}->{ $self->{'mbid'} };

	my $url = "http://coverartarchive.org/release/" . $self->{'mbid'};
	my $url = $url . "/front" if $self->{'use_front'};

	if ($self->load_url($url)) {
		return 1;
	}

	$self->{'releases'}->{ $self->{'mbid'} } = 1;
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

sub remove_relationship {
	print "Removing relationship ".$self->{'rel'}."\n" if $self->{'verbose'};
	my ($self) = @_;
	my $mech = $self->{'mech'};
	my $url = "http://".$self->{'server'}."/edit/relationship/delete?returnto=&type1=url&type0=release&id=".$self->{'rel'};
	my $r = $mech->post($url, {'confirm.edit_note' => $self->{'remove_note'}});
	if ($r->is_success) {
		return 1;
	}
	return undef;
}

sub add_cover_art {
	my ($self) = @_;
	my $mech = $self->{'mech'};

	if (!$self->{'loggedin'}) {
		# load login page
		my $url = "http://".$self->{'server'}."/login";
		print "Logging in as ".$self->{'username'}." at $url.\n" if $self->{'verbose'};
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
	if (-e $self->{'filename'}) {
		$mech2->field("file", $self->{'filename'});
		$mech2->submit();
		if ($mech2->content !~ /parent.document.getElementById/) {
			print STDERR "Error uploading ".$self->{'filename'}." to ".$self->{'mbid'}.".\n";
			return 0;
		}
	} else {
		print STDERR "Could not find ".$self->{'filename'}."\n";
		return 0;
	}

	sleep 1;

	# submit edit
	$mech->form_id("add-cover-art");
	my %types = ( "Front" => 1, "Back" => 2, "Booklet" => 3, "Medium" => 4, "Obi" => 5, "Spine" => 6, "Track" => 7, "Other" => 8 );
	if ($self->{'types'} ne "None") {
		my @types = map { $types{$_} } split /,/, $self->{'types'};
		print "Selecting types ", join (",", @types), "\n" if $self->{'verbose'};
		$mech->select("add-cover-art.type_id", \@types);
	}
	if ($self->{'comment'}) {
		$mech->field("add-cover-art.comment", $self->{'comment'});
		print "Setting comment ".$self->{'comment'}.".\n" if $self->{'verbose'};
	}
	# if user is an autoeditor, do not submit this as an autoedit
	if ($mech->find_all_inputs(type => 'checkbox', name=>'add-cover-art.as_auto_editor')) {
		$mech->untick("add-cover-art.as_auto_editor", "1");
	}
	$mech->field("add-cover-art.edit_note", $self->{'note'});
	$mech->submit();

	print $mech->uri, "\n" if $self->{'verbose'};
	return $mech->uri;
}

1;
