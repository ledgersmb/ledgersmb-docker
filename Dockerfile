FROM        debian:jessie
MAINTAINER  Freelock john@freelock.com

# Install Perl, Tex, Starman, psql client, and all dependencies
RUN echo "APT::Install-Recommends \"false\";\nAPT::Install-Suggests \"false\";" > /etc/apt/apt.conf.d/00recommends && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
  DEBIAN_FRONTEND="noninteractive" apt-get -y install \
  libcgi-emulate-psgi-perl libcgi-simple-perl libconfig-inifiles-perl \
  libdbd-pg-perl libdbi-perl libdatetime-perl \
  libdatetime-format-strptime-perl libdigest-md5-perl \
  libfile-mimeinfo-perl libjson-xs-perl libjson-perl \
  liblocale-maketext-perl liblocale-maketext-lexicon-perl \
  liblog-log4perl-perl libmime-base64-perl libmime-lite-perl \
  libmath-bigint-gmp-perl libmoose-perl libnumber-format-perl \
  libpgobject-perl libpgobject-simple-perl libpgobject-simple-role-perl \
  libpgobject-util-dbmethod-perl libplack-perl libtemplate-perl \
  libnamespace-autoclean-perl \
  libtemplate-plugin-latex-perl libtex-encode-perl \
  libmoosex-nonmoose-perl \
  texlive-latex-recommended \
  texlive-xetex \
  starman \
  libopenoffice-oodoc-perl \
  postgresql-client \
  ssmtp \
  lsb-release \
  && DEBIAN_FRONTEND="noninteractive" apt-get -y autoremove \
  && DEBIAN_FRONTEND="noninteractive" apt-get -y autoclean \
  && rm -rf /var/lib/apt/lists/*


# Build time variables
ENV LSMB_VERSION master
ENV NODE_PATH /usr/local/lib/node_modules

ARG CACHEBUST


###########################################################
# Java & Nodejs for doing Dojo build
# Uglify needs to be installed right before 'make dojo'?!

# These packages are only needed during the dojo build
ENV DOJO_Build_Deps git make gcc libperl-dev npm curl
# These packages can be removed after the dojo build
ENV DOJO_Build_Deps_removal ${DOJO_Build_Deps} nodejs

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install ${DOJO_Build_Deps} && \
    update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100 && \
    cd /srv && \
    git clone --recursive -b $LSMB_VERSION https://github.com/ledgersmb/LedgerSMB.git ledgersmb && \
    cd ledgersmb && \
    curl -L https://cpanmin.us | perl - App::cpanminus && \
    cpanm --quiet --notest \
      --with-feature=starman \
      --with-feature=latex-pdf-ps \
      --with-feature=openoffice \
      --installdeps .  && \
    npm install -g uglify-js@">=2.0 <3.0" && \
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
