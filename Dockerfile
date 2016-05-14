FROM        perl:5
MAINTAINER  Freelock john@freelock.com

# Install Perl, Tex, Starman, psql client, and all dependencies
RUN DEBIAN_FRONTENT=noninteractive && \
  apt-get update && apt-get -y install \
  git \
  libdatetime-perl libdbi-perl libdbd-pg-perl \
  libcgi-simple-perl libtemplate-perl libmime-lite-perl \
  liblocale-maketext-lexicon-perl libtest-exception-perl \
  libtest-trap-perl liblog-log4perl-perl libmath-bigint-gmp-perl \
  libfile-mimeinfo-perl libtemplate-plugin-number-format-perl \
  libdatetime-format-strptime-perl libconfig-general-perl \
  libdatetime-format-strptime-perl libio-stringy-perl libmoose-perl \
  libconfig-inifiles-perl libnamespace-autoclean-perl \
  libcarp-always-perl libjson-perl \
  libtemplate-plugin-latex-perl texlive-latex-recommended \
  libnet-tclink-perl \
  libxml-twig-perl \
  starman \
  postgresql-client-9.4 \
  ssmtp

# Build time variables
ENV LSMB_VERSION 1.5.0-beta5

# Install LedgerSMB
RUN cd /srv && \
  git clone https://github.com/ledgersmb/LedgerSMB.git ledgersmb

WORKDIR /srv/ledgersmb

RUN git checkout master
#RUN git checkout $LSMB_VERSION

# 1.5 requirements
RUN cpanm --quiet --notest \
  --with-feature=starman \
  --with-feature=latex-pdf-ps \
  --with-feature=openoffice \
  --installdeps .


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

COPY start.sh /usr/local/bin/start.sh
COPY update_ssmtp.sh /usr/local/bin/update_ssmtp.sh

RUN chown www-data /etc/ssmtp /etc/ssmtp/ssmtp.conf && \
  chmod +x /usr/local/bin/update_ssmtp.sh /usr/local/bin/start.sh && \
  mkdir -p /var/www


# Internal Port Expose
EXPOSE 5000
#USER www-data

CMD ["start.sh"]
