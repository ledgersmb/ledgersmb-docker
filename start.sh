#!/bin/bash

pushd ~
  mkdir -p .config/mc
  tar Jxf mcthemes.tar.xz
  ./mcthemes/mc_change_theme.sh mcthemes/puthre.theme
popd

update_ssmtp.sh
cd /srv/ledgersmb

# Revalidate the required CPAN packages in case the
# source tree is bind mounted and has changed since Docker build.
#cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
#cpanm --with-develop HTTP::AcceptLanguage

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

# start ledgersmb
if [[ ! -f DEVELOPMENT ]]; then
#  exec plackup --port 5001 --server Starman tools/starman.psgi \
  exec plackup --port 5001 --server HTTP::Server::PSGI tools/starman.psgi \
      --Reload "lib, old/lib, xt/lib, /usr/local/share/perl, /usr/share/perl, /usr/share/perl5"
else
  exec plackup --port 5001 --server HTTP::Server::PSGI tools/starman-development.psgi \
      --workers 1 --env development \
      --Reload "lib, old/lib, xt/lib, /usr/local/share/perl, /usr/share/perl, /usr/share/perl5"
fi

