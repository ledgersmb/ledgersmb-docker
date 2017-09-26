#!/bin/bash

update_ssmtp.sh
cd /srv/ledgersmb

if [[ ! -f ledgersmb.conf ]]; then
  cp conf/ledgersmb.conf.default ledgersmb.conf
  sed -i \
    -e "s/\(cache_templates = \).*\$/cache_templates = 1/g" \
    -e "s/\(host = \).*\$/\1$POSTGRES_HOST/g" \
    -e "s/\(port = \).*\$/\1$POSTGRES_PORT/g" \
    -e "s/\(default_db = \).*\$/\1$DEFAULT_DB/g" \
    -e "s%\(sendmail   = \).*%\1/usr/sbin/ssmtp%g" \
    /srv/ledgersmb/ledgersmb.conf
fi

# Currently unmaintained/untested
# if [ ! -z ${CREATE_DATABASE+x} ]; then
#   perl tools/dbsetup.pl --company $CREATE_DATABASE \
#   --host $POSTGRES_HOST \
#   --postgres_password "$POSTGRES_PASS"
#fi

# Patch Docker ndots:0 sickness
sudo chmod 666 /etc/resolv.conf
echo "options ndots:1" >>/etc/resolv.conf
sudo chmod 644 /etc/resolv.conf

if [[ ! -v DEVELOPMENT || "$DEVELOPMENT" != "1" ]]; then
  #SERVER=Starman
  SERVER=HTTP::Server::PSGI
  PSGI=tools/starman.psgi
else
  SERVER=HTTP::Server::PSGI
  PSGI=tools/starman-development.psgi
  OPT="--workers 1 --env development"
fi

set -x
# start ledgersmb
exec plackup --port 5001 --server $SERVER $PSGI $OPT \
      --Reload "lib, old/lib, xt/lib, t, xt, /usr/local/share/perl, /usr/share/perl, /usr/share/perl5"
