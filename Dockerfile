FROM        debian:buster-slim
MAINTAINER  Freelock john@freelock.com

# Build time variables
ARG LSMB_VERSION="1.9.0-alpha1"
ARG LSMB_DL_DIR="Beta Releases"
ARG ARTIFACT_LOCATION="https://download.ledgersmb.org/f/$LSMB_DL_DIR/$LSMB_VERSION/ledgersmb-$LSMB_VERSION.tar.gz"

# Install Perl, Tex, Starman, psql client, and all dependencies
# Without libclass-c3-xs-perl, performance is terribly slow...

# Installing psql client directly from instructions at https://wiki.postgresql.org/wiki/Apt
# That mitigates issues where the PG instance is running a newer version than this container
# Install Locale::Codes Locale::Country Locale::Language from CPAN to suppress
# deprecation-as-core-module warning

RUN echo -n "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";\n" >> /etc/apt/apt.conf && \
  mkdir -p /usr/share/man/man1/ && \
  mkdir -p /usr/share/man/man2/ && \
  mkdir -p /usr/share/man/man3/ && \
  mkdir -p /usr/share/man/man4/ && \
  mkdir -p /usr/share/man/man5/ && \
  mkdir -p /usr/share/man/man6/ && \
  mkdir -p /usr/share/man/man7/ && \
  mkdir -p /usr/share/man/man8/ && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget ca-certificates gnupg \
    libauthen-sasl-perl libcgi-emulate-psgi-perl libconfig-inifiles-perl \
    libcookie-baker-perl libdbd-pg-perl libdbi-perl libdata-uuid-perl \
    libdatetime-perl libdatetime-format-strptime-perl \
    libemail-sender-perl libemail-stuffer-perl libfile-find-rule-perl \
    libhtml-escape-perl libhttp-headers-fast-perl libio-stringy-perl \
    libjson-maybexs-perl libcpanel-json-xs-perl libjson-pp-perl \
    liblist-moreutils-perl \
    liblocale-maketext-perl liblocale-maketext-lexicon-perl liblog-any-perl \
    liblog-any-adapter-log4perl-perl liblog-log4perl-perl libmime-types-perl \
    libmath-bigint-gmp-perl libmodule-runtime-perl libmoo-perl \
    libmoox-types-mooselike-perl libmoose-perl libmoosex-classattribute-perl \
    libmoosex-nonmoose-perl libnumber-format-perl \
    libpgobject-perl libpgobject-simple-perl libpgobject-simple-role-perl \
    libpgobject-type-bigfloat-perl libpgobject-type-datetime-perl \
    libpgobject-type-bytestring-perl libpgobject-util-dbmethod-perl \
    libpgobject-util-dbadmin-perl libplack-perl \
    libplack-builder-conditionals-perl libplack-middleware-reverseproxy-perl \
    libplack-request-withencoding-perl libscope-guard-perl \
    libsession-storage-secure-perl libstring-random-perl \
    libtemplate-perl libtext-csv-perl libtext-csv-xs-perl \
    libtext-markdown-perl libtry-tiny-perl libversion-compare-perl \
    libxml-libxml-perl libnamespace-autoclean-perl \
    starman starlet libhttp-parser-xs-perl \
    libtemplate-plugin-latex-perl libtex-encode-perl \
    libxml-twig-perl libopenoffice-oodoc-perl \
    libexcel-writer-xlsx-perl libspreadsheet-writeexcel-perl \
    libclass-c3-xs-perl liblocale-codes-perl \
    texlive-plain-generic texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-xetex fonts-liberation \
    lsb-release && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install postgresql-client && \
  DEBIAN_FRONTEND="noninteractive" apt-get -q -y install git cpanminus make gcc libperl-dev && \
  wget --quiet -O /tmp/ledgersmb-$LSMB_VERSION.tar.gz "$ARTIFACT_LOCATION" && \
  tar -xzf /tmp/ledgersmb-$LSMB_VERSION.tar.gz --directory /srv && \
  rm -f /tmp/ledgersmb-$LSMB_VERSION.tar.gz && \
  cpanm --reinstall --notest Locale::Country Locale::Codes Locale::Language && \
  cpanm --notest \
    --with-feature=starman \
    --with-feature=latex-pdf-ps \
    --with-feature=openoffice \
    --installdeps /srv/ledgersmb/ && \
  apt-get purge -q -y git cpanminus make gcc libperl-dev && \
  apt-get autoremove -q -y && \
  apt-get clean -q && \
  rm -rf ~/.cpanm/ /var/lib/apt/lists/* /usr/share/man/*


WORKDIR /srv/ledgersmb

# master requirements

# Configure outgoing mail to use host, other run time variable defaults

## MAIL
ENV LSMB_MAIL_SMTPHOST 172.17.0.1
#ENV LSMB_MAIL_SMTPPORT 25
#ENV LSMB_MAIL_SMTPSENDER_HOSTNAME (container hostname)
#ENV LSMB_MAIL_SMTPTLS
#ENV LSMB_MAIL_SMTPUSER
#ENV LSMB_MAIL_SMTPPASS
#ENV LSMB_MAIL_SMTPAUTHMECH

## DATABASE
ENV POSTGRES_HOST postgres
ENV POSTGRES_PORT 5432
ENV DEFAULT_DB lsmb

COPY start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh && \
  mkdir -p /var/www

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5762

USER www-data
CMD ["start.sh"]
