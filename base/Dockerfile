# Build time variables

ARG SRCIMAGE=debian:trixie-slim

FROM  $SRCIMAGE
LABEL org.opencontainers.image.authors="LedgerSMB project <devel@lists.ledgersmb.org>"
LABEL org.opencontainers.image.title="LedgerSMB double-entry accounting web-application"
LABEL org.opencontainers.image.description="LedgerSMB is a full featured double-entry financial accounting and Enterprise\
 Resource Planning system accessed via a web browser (Perl/JS with a PostgreSQL\
 backend) which offers 'Accounts Receivable', 'Accounts Payable' and 'General\
 Ledger' tracking as well as inventory control and fixed assets handling. The\
 LedgerSMB client can be a web browser or a programmed API call. The goal of\
 the LedgerSMB project is to bring high quality ERP and accounting capabilities\
 to Small and Midsize Businesses."

ARG LSMB_VERSION="1.13.8"
ARG ARTIFACT_PATH="https://download.ledgersmb.org/f/Releases/$LSMB_VERSION/"


# ARTIFACT_PATH is used to work around pre-1.13 Dockerfiles requiring
# the ARTIFACT_LOCATION to point to the artifact, not to its path
RUN set -x ; \
  echo -n "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";\n" >> /etc/apt/apt.conf && \
  mkdir -p /usr/share/man/man1/ && \
  mkdir -p /usr/share/man/man2/ && \
  mkdir -p /usr/share/man/man3/ && \
  mkdir -p /usr/share/man/man4/ && \
  mkdir -p /usr/share/man/man5/ && \
  mkdir -p /usr/share/man/man6/ && \
  mkdir -p /usr/share/man/man7/ && \
  mkdir -p /usr/share/man/man8/ && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y dist-upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y install \
    wget curl ca-certificates libio-socket-ssl-perl postgresql-common && \
  /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y install postgresql-client && \
  cd /srv && \
  curl -s -o ledgersmb-installer -L https://get.ledgersmb.org/ledgersmb-installer && \
  ARTIFACT_LOCATION="$ARTIFACT_PATH" perl ledgersmb-installer install --yes --log-level=trace $LSMB_VERSION && \
  mv /srv/ledgersmb/server-start /usr/local/bin/run.sh && \
  rm -rf ~/.cpanm/ /var/lib/apt/lists/* /usr/share/man/*

WORKDIR /srv/ledgersmb


# master requirements

# Configure outgoing mail to use host, other run time variable defaults

## MAIL
# '__CONTAINER_GATEWAY__' is a magic value which will be substituted
# with the actual gateway IP address
ENV LSMB_MAIL_SMTPHOST=__CONTAINER_GATEWAY__
#ENV LSMB_MAIL_SMTPPORT=25
#ENV LSMB_MAIL_SMTPSENDER_HOSTNAME=(container hostname)
#ENV LSMB_MAIL_SMTPTLS=
#ENV LSMB_MAIL_SMTPUSER=
#ENV LSMB_MAIL_SMTPPASS=
#ENV LSMB_MAIL_SMTPAUTHMECH=

## DATABASE
ENV POSTGRES_HOST=postgres
ENV POSTGRES_PORT=5432
ENV DEFAULT_DB=lsmb

COPY start.sh /usr/local/bin/start.sh
COPY config.sh /usr/local/bin/config.sh

RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/config.sh /usr/local/bin/run.sh && \
  mkdir -p /var/www && \
  mkdir -p /srv/ledgersmb/local/conf && \
  chown -R www-data /srv/ledgersmb/local

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5762

USER www-data
CMD ["start.sh"]
