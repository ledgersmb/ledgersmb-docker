FROM        debian:jessie
MAINTAINER  Freelock john@freelock.com

RUN echo "APT::Install-Recommends \"false\";\nAPT::Install-Suggests \"false\";\n" > /etc/apt/apt.conf.d/00recommends

ENV DEBIAN_FRONTEND=noninteractive

# Install Perl, Tex, Starman, psql client, and all dependencies
RUN apt-get update && apt-get dist-upgrade -y && apt-get -y install \
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
    lsb-release


# Build time variables
ENV LSMB_VERSION 1.5.8

# Install LedgerSMB
RUN apt-get -y install git cpanminus make gcc libperl-dev && \
    cd /srv && \
    curl -Lo ledgersmb-$LSMB_VERSION.tar.gz "https://github.com/ledgersmb/LedgerSMB/releases/download/$LSMB_VERSION/ledgersmb-$LSMB_VERSION.tar.gz" && \
    tar -xvzf ledgersmb-$LSMB_VERSION.tar.gz && \
    rm -f ledgersmb-$LSMB_VERSION.tar.gz && \
    cd ledgersmb && \
    cpanm --quiet --notest \
      --with-feature=starman \
      --with-feature=latex-pdf-ps \
      --with-feature=openoffice \
      --installdeps . && \
    apt-get purge -y git cpanminus make gcc libperl-dev && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf ~/.cpanm/
   

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
# If ledgersmb.conf does not exist, www-data user needs to be able to create it.
RUN chown www-data /srv/ledgersmb
USER www-data

CMD ["start.sh"]
