FROM        debian:stretch
MAINTAINER  Freelock john@freelock.com

# Install Perl, Tex, Starman, psql client, and all dependencies
#
# Without libclass-c3-xs-perl, everything grinds to a halt;
# add it, because it's a 'recommends' it the dep tree, which
# we're skipping, normally
#
# Installing psql client directly from instructions at https://wiki.postgresql.org/wiki/Apt
# That mitigates issues where the PG instance is running a newer version than this container

RUN echo "APT::Install-Recommends \"false\";\nAPT::Install-Suggests \"false\";" > /etc/apt/apt.conf.d/00recommends && \
  DEBIAN_FRONTEND="noninteractive" apt-mark hold sensible-utils && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget ca-certificates gnupg \
    libcgi-emulate-psgi-perl libcgi-simple-perl libconfig-inifiles-perl \
    libdbd-pg-perl libdbi-perl libdata-uuid-perl libdatetime-perl \
    libdatetime-format-strptime-perl libio-stringy-perl \
    libjson-xs-perl libcpanel-json-xs-perl liblist-moreutils-perl \
    liblocale-maketext-perl liblocale-maketext-lexicon-perl \
    liblog-log4perl-perl libmime-lite-perl libmime-types-perl \
    libmath-bigint-gmp-perl libmodule-runtime-perl libmoose-perl \
    libmoosex-nonmoose-perl libnumber-format-perl \
    libpgobject-perl libpgobject-simple-perl libpgobject-simple-role-perl \
    libpgobject-type-bigfloat-perl libpgobject-type-datetime-perl \
    libpgobject-type-bytestring-perl libpgobject-util-dbmethod-perl \
    libpgobject-util-dbadmin-perl libplack-perl libfile-find-rule-perl \
    libplack-middleware-reverseproxy-perl \
    libtemplate-perl libtext-csv-perl libtext-csv-xs-perl \
    libtext-markdown-perl libxml-simple-perl \
    libnamespace-autoclean-perl \
    libimage-size-perl \
    libtemplate-plugin-latex-perl libtex-encode-perl \
    libclass-c3-xs-perl \
    texlive-latex-recommended \
    texlive-xetex fonts-liberation \
    starman \
    libopenoffice-oodoc-perl \
    ssmtp \
    lsb-release && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install postgresql-client && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y autoremove && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y autoclean && \
  rm -rf /var/lib/apt/lists/*


# Build time variables
ENV LSMB_VERSION 1.7.0-beta1
ENV NODE_PATH /usr/local/lib/node_modules


###########################################################
# Java & Nodejs for doing Dojo build
# Uglify needs to be installed right before 'make dojo'?!

# These packages are only needed during the dojo build
ENV DOJO_Build_Deps git make gcc libperl-dev curl nodejs
# These packages can be removed after the dojo build
ENV DOJO_Build_Deps_removal ${DOJO_Build_Deps} nodejs

RUN wget --quiet -O - https://deb.nodesource.com/setup_8.x | bash -
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install ${DOJO_Build_Deps} && \
    cd /srv && \
    git clone --recursive -b $LSMB_VERSION https://github.com/ledgersmb/LedgerSMB.git ledgersmb && \
    cd ledgersmb && \
    (curl -L https://cpanmin.us | perl - App::cpanminus) && \
    cpanm --quiet --notest \
      --with-feature=starman \
      --with-feature=latex-pdf-ps \
      --with-feature=openoffice \
      --installdeps .  && \
    npm install uglify-js@">=2.0 <3.0" && \
    make dojo && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y purge ${DOJO_Build_Deps_removal} && \
    rm -rf /usr/local/lib/node_modules && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y autoremove && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y autoclean && \
    rm -rf ~/.cpanm && \
    rm -rf /var/lib/apt/lists/*

# Cleanup args that are for internal use
ENV DOJO_Build_Deps=
ENV DOJO_Build_Deps_removal=
ENV NODE_PATH=

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
