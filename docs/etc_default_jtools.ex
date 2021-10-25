## samples system defaults per jtools
##
## == summary ==
## || scope || system ||
## || install || /etc/default/jtools ||
##
## == description ==
##
## Contiene le definizioni delle principali variabili di ambiente, in formato shell,
## per jtools:
##

## || JTPATH || elenco di directories dove cercare i progetti, separati da ":", default: /w/prj:/w/work:/w ||

JTPATH="/w/prj:/w/work:/w:/usr/prj"

## || JTCREATEPATH || directory di default dove creare i nuovi progetti, se non definita prende la prima in $JTPATH ||

JTCREATEPATH="/w/prj"


## || JTUSER || default jtools user ||
## || JTGROUP || default jtools group ||

JTUSER="jadmin"
JTGROUP="users"

## || JTVERBOSE || true o false per gestire la loquacita` generale dei comandi ||

JTVERBOSE="true"
