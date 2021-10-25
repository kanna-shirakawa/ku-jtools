#!/bin/bash
#
# __copy1__
# __copy2__
#
## lib,internals definizioni e funzioni standard shell per jtools
##
## == synopsis ==
## === usage ===
##  Includere in testa agli script shell con la forma
##  {{{
##  . ::filename::
##  }}}
##
trap 'echo -e "\n*INTR*\n"; exit 255' 1 2 3
trap 'echo -e "$0: unexpected error $? at $LINENO\n"' ERR


# (questa devo definirla prima perche` usata nelle definizioni vars)
#
_jt_cat()
{
	[ -s "$1" -a -f "$1" ] && cat "$1"
	return 0
}

## == environment (definito in /etc/default/::env.PRJNAME::) ==
##
##  * JTPATH: path di ricerca progetti
##  * JTCREATEPATH: path della directory per la creazione progetti
##  (default, la prima di $JTPATH)
##  * JTUSER: utente di default pre la creazione dei progetti
##  * JTGROUP: gruppo di default pre la creazione dei progetti
##  * JTSCMURL: url predefinito per l'accesso al server SCM (git, bazaar, fossil)
##
export JTPATH=${JTPATH:="/w/prj:/w/work:/w:/w/server/prj:/w/server/work:/w/server/w"}
export JTCREATEPATH=${JTCREATEPATH:-""}
export JTUSER=${JTUSER:="kusa"}
export JTGROUP=${JTGROUP:="users"}
export JTVERBOSE=${JTVERBOSE:-"false"}
export JTSCMURL=${JTSCMURL:-""}

# include definizioni system-wide
#
[ -f __ETC__/default/jtools ] && . __ETC__/default/jtools

#JTCREATEPATH=${JTCREATEPATH:=`echo "$JTPATH" | sed -e 's/:.*//'`}


## == environment (dipendente dal progetto corrente) ==
##
##  * PRJ: path completo della directory principale di progetto
##  * PRJNAME: nome breve del progetto (basename di $PRJ)
##  * PRJDESC: descrizione breve del progetto
##
[ "X${HOME:-}" != "X" ] && {
	export PRJ=${PRJ:-$HOME}
	export PRJNAME=${PRJNAME:-`basename $PRJ`}
	export PRJDESC=${PRJDESC:-`_jt_cat $PRJ/etc/desc`}
}


## == variabili locali (non esportate) ==
##
##  * DEBUG: true=debug attivo (default: false)
##  * VERBOSE: true=verbose, false=quiet (default: true)
##  * CMD: nome del comando senza path
##
DEBUG=false
VERBOSE=true
CMD=`basename $0`


# (FUNCTIONS)

## == funzioni (pseudofunzioni shell) ==
##

## === _jt_cat filename ===
##
## come il comando "cat", legge il contenuto del file ''filename'' e
## lo scrive su standard output, con la differenza che se non esiste
## il file ritorna senza errori e senza output

# (la funzione e` definita in testa)


## === _jt_echo arg(s) ===
## richiama comando "echo", ma solo se $VERBOSE=true
##
_jt_echo()
{
	$VERBOSE && echo -e "$@"
	return 0
}

## === _jt_error status message ===
## emette messaggio definito da ''arg(s)'' su standard error,
## ritorna lo stato ''status'', in modo che e` possibile richiamare questa
## funzione per un'uscita immediata usando, ad esempio, i blocchi:
## {{{
## comando || { _jt_error 123 "messaggio di errore!"; exit $? }
##
## comando || { _jt_error $? "messaggio di errore!"; exit $? }
## }}}
##
_jt_error()
{
	status=$1 ; shift
	echo -e "[err] $*" >&2
	return $status
}



## === _jt_set_vars var(s) ... ===
##
## ... TO BE CONTINUED ...
##
_jt_set_vars()
{
	local var
	local buf=
	local tmp="`mktemp /tmp/${CMD}-var-XXXXXX`"

	rm -f $tmp
	for var in $@
	do
		section=`echo $var | sed -e 's/\..*//'`
		var=`echo $var | sed -e 's/.*\.//'`
		varname="${section}_$var"
		echo "$varname=\"::$section.$var::\"" >>$tmp
	done
	buf=`jtconf-parse --simple $tmp` || {
		status=$?
###echo "-- $tmp dump -------------------------------------------------------------" >&2
###cat $tmp >&2
###echo "-- $tmp dump (end) -------------------------------------------------------" >&2
		rm -f $tmp
		return $status
	}
	rm -f $tmp
	eval "$buf"
}

_jt_normalize_wiki_name()
{
	#echo "$1" | sed -e 's/-//g'
	echo "$1" | sed -e 's/^\(.\)/\u\1/' #-e 's/-//g'
}

_jt_valid_wiki_name()
{
	echo "$1" | grep -q "^[a-zA-Z][a-zA-Z0-9_-]*$"
}


_jt_search_template()
{
	local file=$1
	local dir

	for dir in	$PRJ/etc/templates $PRJ/lib/templates \
			__CONF__/templates \
			__LIB__/templates
	do
		[ -f "$dir/$file" ] && {
			echo "$dir/$file"
			return 0
		}
	done
	return 1
}

_jt_start_input_redirect()
{
	exec 9<&0 <"$1"
}
_jt_end_input_redirect()
{
	exec 0<&9 9<&-
}
