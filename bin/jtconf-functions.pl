#!/usr/bin/perl -w
#
# __copy1__
# __copy2__
#
# v.2.2 (see jtconf main script)
#
use strict;
use Options::File;
use Options::TieFile;

# toolkit defaults (hardwired, if not already env defined)
#
$ENV{'TOOLKIT'}		= "__TOOLKIT__"		if (!defined $ENV{'TOOLKIT'});
$ENV{'TOOLKIT_INST'}	= "__PREFIX__"		if (!defined $ENV{'TOOLKIT_INST'});


# a variable name is composed by a combination of:
#   - a letter
#   - a number
#   - optional, any occurrences of letters, numbers, '_' and '.'
#
# the name must be enclosed inside a pair of delimitators tokens,
# the default is "::" ($DefaultVarTag), that can be modified by callers,
# or by the escaped, alternate one, hardwired ($EscapedVadTag)
#
#my $VarToken	= "[a-zA-Z][a-zA-Z0-9][a-zA-Z0-9_.-=]*";

my $DefaultVarTag = "::";
my $CurrentVarTag = $DefaultVarTag;
my $EscapedVarTag = "_>_";	# escaped alternative vartag

my $VarTag;
my $VarToken;
my $VarMatch;
my $VarEscape	= ":";

my $Debug	= 0;
my $Esc		= "=KK=ESC=KK=";	# escaped value

my $ParseStack	= "";

my %Unresolved;

# declarations
#
sub load_defines(); sub expand_define( $$ ); sub parse_buf( $$$$$ );
sub list_sections($@); sub list_variables($@);
sub VarTag($); sub VarToken($); sub VarMatch($); sub VarEscape($); sub Debug($);
sub is_valid_file($); sub pdebug(@);
sub EscapedVarTag($);

# env defaults
#
$ENV{'LOGNAME'}	= 'nobody'		if (!defined $ENV{'LOGNAME'});
$ENV{'HOME'}	= '/nonexistent'	if (!defined $ENV{'HOME'});
$ENV{'PRJ'}	= $ENV{'HOME'}		if (!defined $ENV{'PRJ'});
if (!defined $ENV{'PRJNAME'}) {
	$ENV{'PRJNAME'}	= $ENV{'PRJ'};
	$ENV{'PRJNAME'}	=~ s/.*\///;
}

# set default vartag and related
#
VarTag( $DefaultVarTag );

1;

sub load_defines()
{
	# crea oggetto database di definizioni,
	#
	## == usage ==
	##
	## Cerca e carica, utilizzando un opportuno path di ricerca, il file
	## $TOOLKIT.conf, eseguendo l'eventuale parsing di variabili del db,
	## per l'elenco delle directories nel path di ricerca vedi dopo.
	##
	## Se nella stessa posizione del file $TOOLKIT.conf esiste un file
	## $TOOLKIT.debug, questo viene caricato, e le sue definizioni vanno
	## in override di quelle normali.
	##
	## Per ciascuna delle directory esistenti nel path, se esiste la subdir *conf.d*
	## questa viene esaminata e tutti i files vengono caricati, senza eccezione,
	## ammesso che si abbiano i permessi di lettura sui files.
	##
	## == path di ricerca ==
	##
	## === environment ===
	##
	##  * PRJ = path del progetto corrente (es: /w/prj/myproject)
	##  * PRJNAME = nome del progetto corrente (es: myproject)
	##  * TOOLKIT = nome dei tools in uso (es: jtools)
	##  * TOOLKIT_INSTDIR = path della directory di installazione del toolkit,
	##  influenza la definizione della directory *etc* (se l'installazione e`
	##  standard, sotto / o sotto /usr, allora la etc e` =/etc=, altrimenti
	##  e` =$TOOLKIT_INSTDIR/etc= (es: /opt/myprog/etc)
	##
	## === environment overrides ===
	##
	##  | JTTMPDIR | |
	##  | RUNDIR | |
	##  | CONFDIR | |
	##  | TOOLKIT | default: __TOOLKIT__ |
	##  | TOOLKIT_INST | default: __TOOLKIT__ |
	##
	my $confdir	= defined $ENV{'CONFDIR'} ? $ENV{'CONFDIR'} : "/etc/$ENV{'PRJNAME'}";
	my $prjname	= $ENV{'PRJNAME'};
	my ( $etcdir, @path, $DIR, $path );

	if ($ENV{'TOOLKIT_INST'} eq "/" || $ENV{'TOOLKIT_INST'} eq "/usr") {
		$etcdir	= "/etc/$ENV{'TOOLKIT'}";
	} else {
		$etcdir	= "$ENV{'TOOLKIT_INST'}/etc";
	}
	pdebug( 1, "DEBUG=$Debug TOOLKIT_INST=$ENV{TOOLKIT_INST} etcdir=$etcdir\n" );
	pdebug( 1, "DEBUG=$Debug TOOLKIT=$ENV{TOOLKIT} PRJNAME=$prjname confdir=$confdir\n" );

	my $CfgDB = new Options::File( "$prjname.conf",
			#MERGE	=> 1,
			TYPE	=> 'LINUX',
			CASE	=> '',
			DEBUG	=> $Debug,
		);

	## === impostazione path di ricerca ===
	##
	##  * $JTTMPDIR/etc/$PRJNAME se definita $JTTMPDIR
	##  * $RUNDIR/etc/$PRJNAME se definita $RUNDIR
	##  * $PRJ/etc/$TOOLKIT se definita $PRJ
	##  * $CONFDIR (defaults to /etc/$PRJNAME)
	##  * /etc/$TOOLKIT (o $TOOLKIT_INST/etc/$TOOLKIT)
	##  * libdir: $TOOLKIT_INST/lib/$TOOLKIT
	##
	push( @path, "$ENV{JTTMPDIR}/etc/$prjname" )	if (defined $ENV{'JTTMPDIR'});
	push( @path, "$ENV{RUNDIR}/etc/$prjname" )	if (defined $ENV{'RUNDIR'});
	push( @path, "$ENV{PRJ}/etc/$ENV{TOOLKIT}" )	if (defined $ENV{'PRJ'});
	push( @path, $confdir );
	push( @path, $etcdir );
	push( @path, "$ENV{TOOLKIT_INST}/lib/$ENV{TOOLKIT}" );
	pdebug( 2, "search path (before normalization): ", join( ", ", @path ), "\n" );

	$CfgDB->path_push( 'RESET', @path );
	die( "path di ricerca vuoto (no dir $confdir o $etcdir)\n" )
		if ( !scalar( $CfgDB->{'_path'} ) );

	pdebug( 1, "search path: ", join( ", ", @{$CfgDB->{'_path'}} ), "\n" );

	# carica, se esiste, il contenuto delle subdirs conf.d; per mantenere
	# la priorita` stabilita dal searchpath, questo viene scansionato al
	# contrario (dall'ultimo elemento al primo), cosi` definizioni in testa
	# al searchpath vanno in override di quelle precedenti
	#
	# poi carica, se esiste, il file diretto (e l'eventuale debugfile)
	#
	# FIXME questo dovrebbe farlo la libreria perl
	#
	@path  = @{ $CfgDB->{_path} };

	while ($path = pop(@path)) {
		$DIR	= "$path/conf.d";
		if (opendir( DIR, $DIR )) {
			pdebug( 1, " checking dir $DIR ..\n" );
			my $file;
			my @files;
			while ($file = readdir( DIR )) {
				push( @files, $file ) if (is_valid_file( "$DIR/$file" ));
			}
			closedir( DIR );
			for $file (sort @files) {
				$CfgDB->read( "$DIR/$file" );	# ignore errors
			}
		}
		$CfgDB->read( "$path/$ENV{TOOLKIT}.conf" );	# ignore errors
		$CfgDB->read( "$path/$ENV{TOOLKIT}.debug" );	# ignore errors
	}

	# infine, carico la sezione speciale env, dall'environment
	# (che deve sempre andare in override)
	#
	do {
		$CfgDB->new_section( "env" );
		foreach my $var (keys %ENV) {
			$CfgDB->value( "env", $var, $ENV{$var} );
		}
	};

	# FIXME questo dovrebbe farlo la libreria perl
	#
	foreach my $sect ($CfgDB->sections()) {
		foreach my $var ($CfgDB->keys($sect)) {
			if (defined $CfgDB->value( $sect, $var ) &&
				    $CfgDB->value( $sect, $var ) eq "undef") {
				$CfgDB->value( $sect, $var, undef );
			}
		}
	}
	pdebug( 9, $CfgDB->DUMP() );
	return $CfgDB;
}


sub expand_define( $$ )
{
	my ($db, $key)	= @_;
	my ($sect, $val);

	# $key	=~ tr/A-Z/a-z/;

	if ($key =~ /\./) {
		# accesso diretto (specificato section.key)
		#
		my @tmp = split( /\./, $key );
		$key	= pop( @tmp );
		$sect	= join( ".", @tmp );
		$val	= $db->value( $sect, $key );
	} else {
	  	# altrimenti cerca in [common] ...
	  	#
	  	$sect	= "common";
	  	if ($db->exists( $sect, $key )) {
			$val = $db->value( $sect, $key );
          	}
	}

	if (!defined $val) {
		if (length($sect) > 40) {
			$sect	= substr( $sect, 0, 40 ) . "(truncated)";
		}
		if (length($key) > 40) {
			$key	= substr( $key, 0, 40 ) . "(truncated)";
		}
		# if you make a mess with escapes and vardelimiters, you can have internal
		# esc marker as variable name, so we unescape the key value to make it right
		if ($key eq $Esc) {
			printf( STDERR "escape value as key? have you messed up escape and var delimiters?\n" );
			$key	=~ s/$Esc/$VarEscape/g;	# resolve escaped
		}
		printf( STDERR "undefined var '%s.%s'\n", $sect, $key );
		return undef;
	}

	pdebug( 4, sprintf( "  found sect=%s, var=%s, value='%s'\n", $sect, $key, $val ) );
	return $val;
}


sub parse_buf( $$$$$ )
{
	my ($db, $buf, $lineno, $recurlevel, $f_parse)	= @_;
	pdebug( 4, "parse_buf( db, buf, lineno=$lineno, recurlevel=$recurlevel )\n" );

	my (@tmp, $out, $val, $var, $idx, $max);
	my $wbuf = $buf;

	my $eol	= "=KK=EOL=KK=";	# end-of-line value
	my $eoe	= "=KK=EOE=KK=";	# escape of escape value

	# on level 0 (file parsing) we use custom vartag (if defined), but for deeper
	# levels (internal variables resolving) we always uses default vartag
	#
	if ($recurlevel) {
		VarTag( $DefaultVarTag );
	} else {
		VarTag( $CurrentVarTag );
	}

	if ($recurlevel == 1) {
		$ParseStack	= "";
	}
	$ParseStack	.= sprintf( "%s\n   --->", $buf );

	pdebug( 4, " wbuf='$wbuf'\n" );

	# per trovare le variabili uso un trucco, splitto il buffer usando la sequenza $VarTag
	# come separatore, tutti gli elementi dispari sono testo, quelli pari
	# sono le variabili (ammesso che soddisfino la sintassi);
	# prima di procedere eseguo escaping del separatore $VarTag; inoltre, dato
	# che un $VarTag a fine riga produce un elemento finale nullo, e quindi inesistente
	# (cioe` non uno vuoto, ma proprio non c'e, ::aaa:: e ::aaa splittati generano
	# la stessa lista di due elementi), aggiungo artificialmente un marker in
	# fondo, che poi togliero a fine parsing
	#
	$wbuf	=~ s/\\\\/$eoe/g;		# escape of escapes
	$wbuf	=~ s/\\$VarEscape/$Esc/g;	# escape start variable sequence

	pdebug( 4, " (esc)'$wbuf'\n" );

	@tmp	= split( /$VarTag/, $wbuf . $eol );
	$idx	= 0;
	$max	= scalar(@tmp);

	pdebug( 4, " \@tmp[$max]=" . join( ", ", @tmp ) . "\n" );

	while ($idx < $max) {
		pdebug( 4, " r=$recurlevel idx=$idx add verbatim '$tmp[$idx]'\n" );
		$out	.= $tmp[$idx];
		pdebug( 4, " r=$recurlevel idx=$idx out='$out'\n" );

		$idx	++;
		last	if ($idx == $max);
		$var	= $tmp[$idx];

		pdebug( 4, " r=$recurlevel idx=$idx examine '$var'\n" );

		# no more elements, it's a marker alone
		#
		if ($idx == ($max-1)) {
			$out	.= $VarTag . $var;
			pdebug( 4, " r=$recurlevel idx=$idx, marker alone, out='$out'\n" );
			$idx++;
			next;
		}

		#if ($var !~ /^$VarToken$/) {	# non e` una variabile
			#$out .= $VarTag . $var . $VarTag;
			#pdebug( 4, ">> not match, out='$out' VarToken='$VarToken'\n" );
			#next;
		#}
		$val	= expand_define( $db, $var );

		if (!defined $val) {
			#printf( STDERR "  in line: %s\n", $buf );
			$out .= $VarTag . $var . $VarTag;
			pdebug( 4, " r=$recurlevel idx=$idx undef, out='$out'\n" );
			#$Unresolved{ sprintf("%06d",$lineno) } = $buf;
			$Unresolved{ sprintf("%06d",$lineno) } = $ParseStack;
			$idx++;
			next;
		}

		# recurse evaluation
		#
		if ($val =~ /$VarTag/) {
			if ($f_parse) {
				pdebug( 5, " r=$recurlevel idx=$idx expansion needed\n" );
				$val = parse_buf( $db, $val, $lineno, $recurlevel+1, $f_parse );
			} else {
				pdebug( 5, " r=$recurlevel idx=$idx expansion needed but disabled\n" );
			}
		}
		$out .= $val;
		pdebug( 4, " r=$recurlevel idx=$idx final, out='$out'\n" );
		$idx++;
	}
	$out	=~ s/$Esc/$VarEscape/g;	# resolve escaped
	$out	=~ s/$eoe/\\\\/g;	# resolve escape of escapes
	$out	=~ s/$eol$//g;		# remove eol marker

	pdebug( 4, "parse_buf(r=$recurlevel) out='$out'\n" );

	if ($recurlevel == 1) {
		# last parsing, unescape alternative vartags
		#
		$out	=~ s/$EscapedVarTag/$VarTag/g;
	}
	return $out;
}

sub VarTag($) 
{
	if (@_) {
		my ($char);
		$VarTag = $_[0];
		$VarToken = "";
		foreach $char (split( "", $VarTag )) {
			$VarToken .= "[^${char}]";
		}
		$VarMatch = $VarTag . $VarToken . $VarTag;
		pdebug( 2, "set VarTag='$VarTag' VarToken='$VarToken' VarMatch='$VarMatch'\n" );
	}
	return $VarTag;
}

sub VarToken($)		{ $VarToken = $_[0] if (@_); return $VarToken; }
sub VarMatch($)		{ $VarMatch = $_[0] if (@_); return $VarMatch; }
sub VarEscape($)	{ $VarEscape = $_[0] if (@_); return $VarEscape; }
sub EscapedVarTag($)	{ $EscapedVarTag = $_[0] if (@_); return $EscapedVarTag; }
sub Debug($)		{ $Debug = $_[0] if (@_); return $Debug; }
sub Unresolved		{ return %Unresolved; }


sub list_sections($@)
{
	my $db		= shift;
	my $w_regexp	= shift;
	my @matches	= @_;
	my $match;
	my $sect;
	my $found;
	my @out		= ();

	foreach $sect ($db->sections()) {
		if (@matches) {
			$found = 0;
			foreach $match (@matches) {
				if ($w_regexp) {
					if ($sect =~ /^$match/) {
						$found = 1;
						last;
					}
				} else {
					if (substr($sect,0,length($match)) eq $match) {
						$found = 1;
						last;
					}
				}
			}
		} else {
			$found = 1;
		}
		push( @out, $sect )	if ($found);
	}
	return @out;
}

sub list_variables($@)
{
	my $db		= shift;
	my $section	= shift;
	my @out		= ();

	if ($db->exists( $section )) {
		##my @out = $db->keys( $section, 'LOCAL' );
		# 2009.10.03 lc01 - tolto LOCAL per elencare anche vars ereditate
		@out	= $db->keys( $section );
	}
	return @out;
}


sub is_valid_file( $ )
{
	my ($file) = @_;
	return 	if (! -f $file);
	return	if (! -r $file);
	return 	if ($file =~ /\.rpmsave$/);
	return 	if ($file =~ /\.rpmnew$/);
	return 	if ($file =~ /\.bak$/);
	return 	if ($file =~ /\.offline$/);
	return	if ($file =~ /\.old$/);
	return	if ($file =~ /\.tmp$/);
	return	if ($file =~ /~$/);
	return	if ($file =~ /\/tmp[^\/]+$/);
	return 1;
}

sub pdebug(@)
{
	my $lev	= shift(@_);
	print STDERR "D> ", @_	if ($lev <= $Debug);
}
