FROM        ubuntu:xenial
MAINTAINER  Freelock john@freelock.com

RUN echo -n "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";\n" >> /etc/apt/apt.conf

# Install Perl, Tex, Starman, psql client, and all dependencies
RUN DEBIAN_FRONTEND=noninteractive && \
  apt-get update && apt-get -y install \
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
  libmoosex-nonmoose-perl libclass-c3-xs-perl \
  texlive-latex-recommended \
  texlive-xetex \
  starman \
  libopenoffice-oodoc-perl \
  postgresql-client libtap-parser-sourcehandler-pgtap-perl pgtap postgresql-pgtap \
  ssmtp sudo xz-utils curl \
  git cpanminus make gcc libperl-dev lsb-release

# Java & Nodejs for doing Dojo build
#RUN DEBIAN_FRONTENT=noninteractive && apt-get install -y openjdk-7-jre-headless
# Local development tools
RUN apt-get update && \
  apt install -qyy mc gettext sudo bzip2 bash-completion less meld xauth \
                   lynx dnsutils net-tools \
                   npm && \
  rm -rf /var/lib/apt/lists/*
RUN update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100

# Build time variables
ENV LSMB_VERSION master
#ARG CACHEBUST

# Install LedgerSMB
WORKDIR /srv
RUN git clone --recursive -b $LSMB_VERSION https://github.com/ledgersmb/LedgerSMB.git ledgersmb

# Uglify needs to be installed right before 'make dojo'?!
RUN npm install -g uglify-js@">=2.0 <3.0"
ENV NODE_PATH /usr/local/lib/node_modules

WORKDIR /srv/ledgersmb

# Build dojo
RUN make dojo

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

# Make sure www-data share the uid/gid of the container owner on the host
#RUN groupmod --gid $HOST_GID www-data
#RUN usermod --uid $HOST_UID --gid $HOST_GID www-data
RUN groupmod --gid 1000 www-data
RUN usermod --uid 1000 --gid 1000 www-data

WORKDIR /srv/ledgersmb

COPY cpanfile /srv/ledgersmb/cpanfile
# master requirements
RUN cpanm --quiet --notest \
  --with-feature=starman \
  --with-feature=latex-pdf-ps \
  --with-feature=openoffice \
  --with-feature=latex-pdf-images \
  --with-feature=latex-pdf-ps \
  --with-feature=edi \
  --with-feature=xls \
  --with-feature=debug \
  --with-develop \
  --installdeps .

# Fix Module::Runtime of old distros
RUN cpanm Data::Printer \
	Devel::hdb Plack::Middleware::Debug::Log4perl \
	Devel::NYTProf \
    Plack::Middleware::Debug::DBIProfile \
    Plack::Middleware::Debug::DBITrace \
    Plack::Middleware::Debug::Log4perl \
    Plack::Middleware::Debug::Profiler::NYTProf \
    Plack::Middleware::Debug::W3CValidate \
	Plack::Middleware::InteractiveDebugger \
    WebService::Validator::HTML::W3C && \
	npm install floatthead

# Work around an aufs bug related to directory permissions:
RUN mkdir -p /tmp && \
  chmod 1777 /tmp

# Internal Port Expose
EXPOSE 5001

RUN cpanm --quiet --notest --force \
    HTTP::Exception Module::Versions \
    MooseX::Constructor::AllErrors TryCatch \
    Text::PO::Parser Class::Std::Utils IO::File Devel::hdb Devel::Trepan && \
    rm -r ~/.cpanm

COPY start.sh /usr/local/bin/start.sh
COPY update_ssmtp.sh /usr/local/bin/update_ssmtp.sh

RUN chown www-data /etc/ssmtp /etc/ssmtp/ssmtp.conf && \
  chmod +x /usr/local/bin/update_ssmtp.sh /usr/local/bin/start.sh && \
  mkdir -p /var/www && chown www-data:www-data /var/www

# Add sudo capability
RUN echo "www-data ALL=NOPASSWD: ALL" >>/etc/sudoers

# Burst the Docker cache based on a flag file,
# computed from the SHA of the head of git tree (when bind mounted)
COPY ledgersmb.rebuild /var/www/ledgersmb.rebuild
COPY git-colordiff.sh /var/www/git-colordiff.sh

# Add temporary patches
#COPY patch/patches.tar /tmp
#RUN cd / && tar xvf /tmp/patches.tar && rm /tmp/patches.tar
ENV LANG=C.UTF-8

RUN mkdir -p /usr/share/sql-ledger/users
COPY sql-ledger/users/members /usr/share/sql-ledger/users/members

USER www-data
WORKDIR /var/www
RUN xauth add ylaho3:0 MIT-MAGIC-COOKIE-1 083b320b62214727060c3468777f3333

COPY mcthemes.tar.xz /var/www/mcthemes.tar.xz

RUN cd /var/www && \
  mkdir -p .config/mc && \
  touch .config/mc/ini && \
  tar Jxf mcthemes.tar.xz && \
  ./mcthemes/mc_change_theme.sh mcthemes/puthre.theme

WORKDIR /srv/ledgersmb

CMD ["start.sh"]
