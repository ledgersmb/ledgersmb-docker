#!/bin/bash

update_ssmtp.sh
cd /srv/ledgersmb

if [[ ! -f ledgersmb.conf ]]; then
  cat <<EOF >/tmp/ledgersmb.conf
[main]
cache_templates = 1

[database]
host = $POSTGRES_HOST
port = $POSTGRES_PORT
default_db = $DEFAULT_DB

[mail]
sendmail   = /usr/sbin/ssmtp

EOF
  export LSMB_CONFIG_FILE='/tmp/ledgersmb.conf'
fi

# Currently unmaintained/untested
# if [ ! -z ${CREATE_DATABASE+x} ]; then
#   perl tools/dbsetup.pl --company $CREATE_DATABASE \
#   --host $POSTGRES_HOST \
#   --postgres_password "$POSTGRES_PASS"
#fi

# start ledgersmb
exec starman --port 5762 tools/starman.psgi
