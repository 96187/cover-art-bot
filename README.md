This is a little bot for adding things to the [Cover Art Archive](http://coverartarchive.org) from arbitrary URLs. You'll need a username and password from [MusicBrainz](http://musicbrainz.org) to use it, since that's how edits on the cover art archive happen. Read the header of bot.pl to learn how to use it.

Run it using: perl bot.pl [options] datafile username

"username" is your username on musicbrainz.org.

"datafile" should be a tab-separated data file with the following fields:
MBID
Filename or URL
Relationship ID (l_release_url.id) if you want to delete a relationship (optional)
Type(s), separated by a comma (e.g. "Front", "Back,Spine"). Defaults to "Front" if left blank. Use "None" if you really don't want to set a type.
Comment (optional)


Options:
-n --note: edit note to use (default 'from existing cover art relationship')
-m --max: how many (max) pieces to upload in a given run (default: 2)
-t --tmpdir: a temporary directory (default: "/tmp/")
-p --password: password (if not provided, will prompt)
-r --remove-note: edit note to use when removing a relationship (default 'cover added to cover art archive')
-l --local: files are local, not URLs

Right now it will only upload images if there isn't any cover art already. This may or may not ever get fixed.
