use Ace::Browser::LocalSiteDefs '$HTML_PATH';

# ========= DIRECTORIES =======
# base of all our scripts
$ROOT = '/cgi-bin/ace';

# base of our html files
$DOCROOT = '/ace';

# base of our icons
$ICONS = "$DOCROOT/icons";

# base of our images
$IMAGES = "$DOCROOT/images";

# ========= $HOST  =========
# name of the host to connect to
$HOST = 'stein.cshl.org';

# ========= $PORT  =========
# Port number to connect to
$PORT = 2005;

# ========= $USERNAME  =========
# Username for connections (none)
$USERNAME = '';

# ========= $PASSWORD  =========
# Password for connections (none)
$PASSWORD = '';

# ========= $STYLESHEET =========
# stylesheet to use
$STYLESHEET = "$DOCROOT/stylesheets/aceperl.css";

# ========= $PICTURES ==========
# Where to write temporary picture files to:
#   The URL and the physical location, which must be writable
# by the web server.  This is meaningless under Apache::Modperl.
# Otherwise the value is determined by Makefile.PL
@PICTURES = ($IMAGES => "$HTML_PATH/images");

# ========= @SEARCHES  =========
# search scripts available
# NOTE: the order is important
@SEARCHES   = (
	       text => {
			name   => 'Text Search',
			url    =>"$ROOT/searches/text",
		       },
	       browser => {
			   name => 'Class Browser',
			   url  => "$ROOT/searches/browser",
			  },
	       query => {
			 name => 'Acedb Query',
			 url  => "$ROOT/searches/query",
			 },
	       );
$SEARCH_ICON = '/ace/icons/unknown.gif';

# ========= %HOME  =========
# Home page URL
@HOME      = (
	      $DOCROOT => 'Home Page'
	     );

# ========= %DISPLAYS =========
# displays to show
%DISPLAYS = (	
	     tree => {
		      'url'     => "generic/tree",
		      'label'   => 'Tree Display',
		      'icon'    => '/icons/text.gif' },
	     pic => {
		     'url'     => "generic/pic",
		     'label'   => 'Graphic Display',
		     'icon'    => '/icons/image2.gif' },
	     xml => {
		     'url'     => "generic/xml",
		     'label'   => 'XML Display',
		     'icon'    => '/icons/text.gif' },
	     model => {
		     'url'     => "generic/model",
		     'label'   => 'AceDB Schema',
		     'icon'    => '/icons/text.gif' },
	    );

# ========= %CLASSES =========
# displays to show
%CLASSES = (	
	    # default is a special "dummy" class to fall back on
	     Default => [ qw/tree pic model xml/ ],
	   );


# ========= &URL_MAPPER  =========
# mapping from object type to URL.  Return empty list to fall through
# to default.
sub URL_MAPPER {
  my ($display,$name,$class) = @_;

  # Small Ace inconsistency: Models named "#name" should be
  # transduced to Models named "?name"
  $name = "?$1" if $class eq 'Model' && $name=~/^\#(.*)/;

  my $n = CGI->escape("$name"); # looks superfluous, but avoids Ace::Object name conversions errors
  my $c = CGI->escape($class);

  # pictures remain pictures
  if ($display eq 'pic') {
    return ('pic' => "name=$n&class=$c");
  }
  # otherwise display it with a tree
  else {
    return ('tree' => "name=$n&class=$c");
  }
}

# ========= $BANNER =========
# Banner HTML
# This will appear at the top of each page. 
$BANNER = <<END;
<font size="+5" color="red">AceDB Database on $HOST:$PORT</font>
END
;

# ========= PRIVACY STATEMENT
$PRINT_PRIVACY_STATEMENT = 1;

# ========= FEEDBACK STATEMENT
@FEEDBACK_RECIPIENTS = (
			[ " $ENV{SERVER_ADMIN}", 'general complaints and suggestions', 1 ]
);

# ========= $FOOTER =========
# Footer HTML
# This will appear at the bottom of each page
$FOOTER = '';

# configuration for the "basic" seqarch script
@BASIC_OBJECTS = 
  ('Any'      =>   '<i>Anything</i>',
   'Locus'    =>   'Confirmed Gene',
   'Predicted_gene'    =>   'Predicted Gene',
   'Sequence' =>   'Sequence (any)',
   'Genome_sequence', => 'Sequence (genomic)',
   'Author'       =>    'Author',
   'Genetic_map'  => 'Genetic Map',
   'Sequence_map' => 'Sequence Map',
   'Strain'       =>  'Worm Strain',
   'Clone'        => 'Clone'
  );

1;
