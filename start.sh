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

[proxy]
ip=${PROXY_IP:-172.17.0.1/16}
EOF
  export LSMB_CONFIG_FILE='/tmp/ledgersmb.conf'
fi

if [ ! -d "/tmp/ledgersmb" ]; then
  mkdir -p /tmp/ledgersmb
fi

# start ledgersmb
# --preload-app allows application initialization to kill the entire
# starman instance (instead of just the worker, which will immediately
# get restarted); it also has a positive effect on memory use

exec starman --port 5762 --workers ${LSMB_WORKERS:-5} -I lib -I old/lib \
        --preload-app bin/ledgersmb-server.psgi
