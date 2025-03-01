FROM lsmb-split:latest
#FROM ledgersmb/ledgersmb:1.11.18
USER root

# Remove inherited start.sh
RUN rm -rf /usr/local/bin/start.sh

# Install nginx and other dependencies
RUN set -x && \
    apt-get update -y && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
    nginx wget xz-utils
    mkdir -p /var/lib/nginx/body /var/cache/nginx

COPY nginx.conf /etc/nginx/nginx.conf

# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.2.0.2

RUN set -ex && \
  ARCH="x86_64" && \
  wget -O /tmp/s6-overlay-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
  wget -O /tmp/s6-overlay-noarch.tar.xz.sha256 https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 && \
  wget -O /tmp/s6-overlay-${ARCH}.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz && \
  wget -O /tmp/s6-overlay-${ARCH}.tar.xz.sha256 https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz.sha256 && \
  wget -O /tmp/s6-overlay-symlinks-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz && \
  wget -O /tmp/s6-overlay-symlinks-noarch.tar.xz.sha256 https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz.sha256 && \
  cd /tmp && \
  sha256sum -c *.sha256 && \
  tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
  tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz && \ 
  tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz

# Configure nginx and starman with s6
COPY services/starman/run /etc/services.d/starman/run
RUN chmod +x /etc/services.d/starman/run

COPY services/nginx/run /etc/services.d/nginx/run
RUN chmod +x /etc/services.d/nginx/run

COPY scripts/ledgersmb_config /etc/s6-overlay/s6-rc.d/ledgersmb_config
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/ledgersmb_config
RUN chmod +x /etc/s6-overlay/s6-rc.d/ledgersmb_config/up

EXPOSE 80

#USER www-data
ENTRYPOINT ["/init"]
