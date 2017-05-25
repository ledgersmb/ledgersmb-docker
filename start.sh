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

if [ ! -f "/tmp/ledgersmb" ]; then
  mkdir /tmp/ledgersmb
fi
# Currently unmaintained/untested
# if [ ! -z ${CREATE_DATABASE+x} ]; then
#   perl tools/dbsetup.pl --company $CREATE_DATABASE \
#   --host $POSTGRES_HOST \
#   --postgres_password "$POSTGRES_PASS"
#fi

# Needed for modules loaded by cpanm
export PERL5LIB
for PerlLib in /usr/lib/perl5* /usr/local/lib/perl5*/site_perl/* ; do
    [[ -d "$PerlLib" ]] && {
        PERL5LIB="$PerlLib";
        echo -e "\tmaybe: $PerlLib";
    }
done ;
echo "Selected PERL5LIB=$PERL5LIB";

# start ledgersmb
# --preload-app allows application initialization to kill the entire
# starman instance (instead of just the worker, which will immediately
# get restarted); it also has a positive effect on memory use
exec starman --port 5762 --preload-app tools/starman.psgi
