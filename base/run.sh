#!/bin/bash

cd /srv/ledgersmb
LSMB_CONFIG_FILE=${LSMB_CONFIG_FILE:-./local/conf/ledgersmb.yaml}
export LSMB_CONFIG_FILE
echo '--------- LEDGERSMB CONFIGURATION:  ledgersmb.conf'
cat ${LSMB_CONFIG_FILE}
echo '--------- LEDGERSMB CONFIGURATION --- END'

# ':5762:' suppresses an uninitialized variable warning in starman
# the last colon means "don't connect using tls"; without it, there's a warning
exec starman --listen 0.0.0.0:5762 --workers ${LSMB_WORKERS:-5} \
             -I lib -I old/lib \
             --preload-app bin/ledgersmb-server.psgi
