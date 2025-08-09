#!/bin/bash

home_dir="$(dirname $(readlink -f $BASH_SOURCE))"
"$home_dir/config.sh" || { echo "Failed configuration" ; exit 1 }

LSMB_CONFIG_FILE="${LSMB_CONFIG_FILE:-/srv/ledgersmb/local/conf/ledgersmb.yaml}"
export LSMB_CONFIG_FILE
echo "--------- LEDGERSMB CONFIGURATION:  $LSMB_CONFIG_FILE"
cat "${LSMB_CONFIG_FILE}"
echo '--------- LEDGERSMB CONFIGURATION --- END'

exec "$home_dir/run.sh"
