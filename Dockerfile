# Build time variables

ARG SRCIMAGE=debian:stretch-slim


FROM  $SRCIMAGE AS builder

ARG LSMB_VERSION="1.7.36"
ARG LSMB_DL_DIR="Releases"
ARG ARTIFACT_LOCATION="https://download.ledgersmb.org/f/$LSMB_DL_DIR/$LSMB_VERSION/ledgersmb-$LSMB_VERSION.tar.gz"


RUN set -x ; \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install dh-make-perl libmodule-cpanfile-perl git wget && \
  apt-file update

RUN set -x ; \
  wget --quiet -O /tmp/ledgersmb-$LSMB_VERSION.tar.gz "$ARTIFACT_LOCATION" && \
  tar -xzf /tmp/ledgersmb-$LSMB_VERSION.tar.gz --directory /srv && \
  rm -f /tmp/ledgersmb-$LSMB_VERSION.tar.gz && \
  cd /srv/ledgersmb && \
  ( ( for lib in $( cpanfile-dump --with-all-features --recommends --no-configure --no-build --no-test ) ; \
    do \
      if dh-make-perl locate "$lib" 2>/dev/null ; \
      then  \
        : \
      else \
        echo no : $lib ; \
      fi ; \
    done ) | grep -v dh-make-perl | grep -v 'not found' | grep -vi 'is in Perl ' | cut -d' ' -f4 | sort | uniq | tee /srv/derived-deps ) && \
  cat /srv/derived-deps


#
#
#  The real image build starts here
#
#


FROM  $SRCIMAGE
MAINTAINER  Freelock john@freelock.com


# Build time variables
ARG LSMB_VERSION="1.7.36"
ARG LSMB_DL_DIR="Releases"
ARG ARTIFACT_LOCATION="https://download.ledgersmb.org/f/$LSMB_DL_DIR/$LSMB_VERSION/ledgersmb-$LSMB_VERSION.tar.gz"

# Install Perl, Tex, Starman, psql client, and all dependencies
# Without libclass-c3-xs-perl, performance is terribly slow...
# Without libclass-accessor-lite-perl, HTML::Entities won't build from CPAN
# libnet-cidr-lite-perl is a dependency for Plack::Builder::Conditionals
#   which is being installed from CPAN
# libtest-requires-perl is a dependency of Module-Build-Pluggable-PPPort
#   on which HTML::Escape depends

# Installing psql client directly from instructions at https://wiki.postgresql.org/wiki/Apt
# That mitigates issues where the PG instance is running a newer version than this container


COPY --from=builder /srv/derived-deps /tmp/derived-deps

RUN set -x ; \
  echo -n "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";\n" >> /etc/apt/apt.conf && \
  mkdir -p /usr/share/man/man1/ && \
  mkdir -p /usr/share/man/man2/ && \
  mkdir -p /usr/share/man/man3/ && \
  mkdir -p /usr/share/man/man4/ && \
  mkdir -p /usr/share/man/man5/ && \
  mkdir -p /usr/share/man/man6/ && \
  mkdir -p /usr/share/man/man7/ && \
  DEBIAN_FRONTEND="noninteractive" apt-get update -q && \
  DEBIAN_FRONTEND="noninteractive" apt-get dist-upgrade -y -q && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y -q install \
    wget ca-certificates gnupg \
    $( cat /tmp/derived-deps ) \
    libclass-c3-xs-perl libclass-accessor-lite-perl \
    texlive-latex-recommended texlive-fonts-recommended \
    texlive-xetex fonts-liberation \
    ssmtp \
    lsb-release && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y install postgresql-client && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y install git cpanminus make gcc libperl-dev && \
  wget --quiet -O /tmp/ledgersmb-$LSMB_VERSION.tar.gz "$ARTIFACT_LOCATION" && \
  tar -xzf /tmp/ledgersmb-$LSMB_VERSION.tar.gz --directory /srv && \
  rm -f /tmp/ledgersmb-$LSMB_VERSION.tar.gz && \
  cpanm --notest \
    --with-feature=starman \
    --with-feature=latex-pdf-ps \
    --with-feature=openoffice \
    --installdeps /srv/ledgersmb/ && \
  apt-get purge -q -y git cpanminus make gcc libperl-dev && \
  apt-get autoremove -q -y && \
  apt-get autoclean -q && \
  rm -rf ~/.cpanm/ && \
  rm -rf /var/lib/apt/lists/* /usr/share/man/*


WORKDIR /srv/ledgersmb

# master requirements

# Configure outgoing mail to use host, other run time variable defaults

## sSMTP
ENV SSMTP_ROOT ar@example.com
ENV SSMTP_MAILHUB 172.17.0.1
ENV SSMTP_HOSTNAME 172.17.0.1
#ENV SSMTP_USE_STARTTLS
#ENV SSMTP_AUTH_USER
#ENV SSMTP_AUTH_PASS
ENV SSMTP_FROMLINE_OVERRIDE YES
#ENV SSMTP_AUTH_METHOD

ENV POSTGRES_HOST postgres
ENV POSTGRES_PORT 5432
ENV DEFAULT_DB lsmb

COPY start.sh /usr/local/bin/start.sh
COPY update_ssmtp.sh /usr/local/bin/update_ssmtp.sh

RUN chown www-data /etc/ssmtp /etc/ssmtp/ssmtp.conf && \
  chmod +x /usr/local/bin/update_ssmtp.sh /usr/local/bin/start.sh && \
  mkdir -p /var/www

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && \
  chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5762

USER www-data
CMD ["start.sh"]
