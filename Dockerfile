FROM        perl:5
MAINTAINER  Freelock john@freelock.com

# Build time variables
ENV LSMB_VERSION 1.4.28


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
  texlive-latex-base texlive-latex-extra \
  texlive-xetex \
  libxml-twig-perl \
  libtex-encode-perl \
  libdevel-trace-perl \
  starman \
  postgresql-client-9.4 \
  ssmtp

# Install LedgerSMB

RUN cd /srv && \
  git clone https://github.com/ledgersmb/LedgerSMB.git ledgersmb

WORKDIR /srv/ledgersmb

RUN git checkout $LSMB_VERSION

#RUN sed -i \
#  -e "s/short_open_tag = Off/short_open_tag = On/g" \
#  -e "s/post_max_size = 8M/post_max_size = 20M/g" \
#  -e "s!^;sendmail_path =.*\$!sendmail_path = /usr/sbin/ssmtp -t!g" \
#  /etc/php5/fpm/php.ini && \

# Configure outgoing mail to use host, other run time variable defaults

## sSMTP
ENV SSMTP_ROOT ar@example.com
ENV SSMTP_MAILHUB 172.17.42.1
ENV SSMTP_HOSTNAME 172.17.42.1
#ENV SSMTP_USE_STARTTLS
#ENV SSMTP_AUTH_USER
#ENV SSMTP_AUTH_PASS
ENV SSMTP_FROMLINE_OVERRIDE YES
#ENV SSMTP_AUTH_METHOD

ENV POSTGRES_HOST postgres

COPY start.sh /usr/bin/start.sh
COPY update_ssmtp.sh /usr/bin/update_ssmtp.sh

#RUN  cpanm \
#   CGI::Compile


RUN chown www-data /etc/ssmtp /etc/ssmtp/ssmtp.conf && \
  chmod +x /usr/bin/update_ssmtp.sh /usr/bin/start.sh && \
  mkdir -p /var/www

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && \
  chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5000
#USER www-data

CMD ["start.sh"]
