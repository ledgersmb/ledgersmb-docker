# Build time variables

ARG SRCIMAGE=debian:bullseye-slim


FROM  $SRCIMAGE AS builder

ENV LSMB_VERSION master


RUN set -x ; \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install dh-make-perl libmodule-cpanfile-perl git wget && \
  apt-file update

RUN set -x ; \
  cd /srv && \
  git clone --depth 1 --recursive -b $LSMB_VERSION https://github.com/ledgersmb/LedgerSMB.git ledgersmb && \
  cd ledgersmb && \
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
LABEL   org.opencontainers.image.authors="LedgerSMB project <devel@lists.ledgersmb.org>"

# Install Perl, Tex, Starman, psql client, and all dependencies
#
# Without libclass-c3-xs-perl, everything grinds to a halt;
# add it, because it's a 'recommends' it the dep tree, which
# we're skipping, normally
#
# Installing psql client directly from instructions at https://wiki.postgresql.org/wiki/Apt
# That mitigates issues where the PG instance is running a newer version than this container

COPY --from=builder /srv/derived-deps /tmp/derived-deps

RUN set -x ; \
  echo "APT::Install-Recommends \"false\";\nAPT::Install-Suggests \"false\";\n" > /etc/apt/apt.conf.d/00recommends && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget ca-certificates gnupg \
    $( cat /tmp/derived-deps ) \
    libclass-c3-xs-perl \
    texlive-plain-generic texlive-latex-recommended texlive-fonts-recommended \
    texlive-xetex fonts-liberation \
    lsb-release && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install postgresql-client && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y autoremove && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y autoclean && \
  rm -rf /var/lib/apt/lists/*


# Build time variables
ENV LSMB_VERSION master
ENV NODE_PATH /usr/local/lib/node_modules


###########################################################
# Java & Nodejs for doing Dojo build

# These packages are only needed during the dojo build
ENV DOJO_Build_Deps git make gcc libperl-dev curl nodejs cpanminus
# These packages can be removed after the dojo build
ENV DOJO_Build_Deps_removal ${DOJO_Build_Deps} nodejs cpanminus

RUN wget --quiet -O - https://deb.nodesource.com/setup_16.x | bash -
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install ${DOJO_Build_Deps} && \
    cd /srv && \
    git clone --depth 1 --recursive -b $LSMB_VERSION https://github.com/ledgersmb/LedgerSMB.git ledgersmb && \
    cd ledgersmb && \
    cpanm --quiet --notest \
      --with-feature=starman \
      --with-feature=latex-pdf-ps \
      --with-feature=openoffice \
      --installdeps .  && \
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

## MAIL
ENV LSMB_MAIL_SMTPHOST 172.17.0.1
#ENV LSMB_MAIL_SMTPPORT 25
#ENV LSMB_MAIL_SMTPSENDER_HOSTNAME (container hostname)
#ENV LSMB_MAIL_SMTPTLS
#ENV LSMB_MAIL_SMTPUSER
#ENV LSMB_MAIL_SMTPPASS
#ENV LSMB_MAIL_SMTPAUTHMECH

ENV POSTGRES_HOST postgres
ENV POSTGRES_PORT 5432
ENV DEFAULT_DB lsmb

COPY start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh && \
    mkdir -p /var/www

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && \
  chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5762

USER www-data
CMD ["start.sh"]
