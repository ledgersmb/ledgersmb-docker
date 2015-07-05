#!/bin/bash

if [[ -e /tmp/smtpconfig ]]; then
  echo "smtp configured."
else
  update_ssmtp.sh
  touch /tmp/smtpconfig
fi


if [[ ! -f ledgersmb.conf ]]; then
  cp ledgersmb.conf.default ledgersmb.conf
  sed -i \
    -e "s/\(cache_templates = \).*\$/cache_templates = 1/g" \
    -e "s/\(host = \).*\$/\1$POSTGRES_HOST/g" \
    -e "s%\(sendmail   = \).*%\1/usr/bin/ssmtp%g" \
    /srv/ledgersmb/ledgersmb.conf
fi

if [ ! -z ${CREATE_DATABASE+x} ]; then
  perl tools/dbsetup.pl --company $CREATE_DATABASE \
  --host $POSTGRES_HOST \
  --postgres_password "$POSTGRES_PASS"
fi

# start ledgersmb
exec starman tools/starman.psgi
