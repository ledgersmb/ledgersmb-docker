#!/bin/bash

update_ssmtp.sh


if [[ ! -f ledgersmb.conf ]]; then
  cp ledgersmb.conf.default ledgersmb.conf
  sed -i \
    -e "s/\(cache_templates = \).*\$/cache_templates = 1/g" \
    -e "s/\(host = \).*\$/\1$POSTGRES_HOST/g" \
    -e "s/\(port = \).*\$/\1$POSTGRES_PORT/g" \
    -e "s/\(default_db = \).*\$/\1$DEFAULT_DB/g" \
    -e "s%\(sendmail   = \).*%\1/usr/sbin/ssmtp%g" \
    /srv/ledgersmb/ledgersmb.conf
fi

if [ ! -z ${CREATE_DATABASE+x} ]; then
  perl tools/prepare-company-database.pl --company $CREATE_DATABASE \
  --host $POSTGRES_HOST \
  --owner postgres \
  --password "$POSTGRES_PASS"
fi

# start ledgersmb
exec starman tools/starman.psgi
