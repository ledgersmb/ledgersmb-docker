# Install LedgerSMB version
ARG LSMB_VERSION="1.13.0"
# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.2.0.2

FROM ledgersmb/ledgersmb:$LSMB_VERSION-base

# Repeat args if we still want to use them
ARG LSMB_VERSION
ARG S6_OVERLAY_VERSION

# Install nginx and other dependencies
USER root
RUN set -x && \
    DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx wget xz-utils && \
    mkdir -p /var/lib/nginx/body /var/cache/nginx && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -q -y && \
    DEBIAN_FRONTEND=noninteractive apt-get clean -q && \
    ARCH="$(case "$(dpkg --print-architecture)" in armv7*|armhf) echo "armhf" ;; arm64) echo "aarch64" ;; amd64) echo "x86_64" ;; *) exit 1 ;; esac)" && \
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
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    rm -rf ~/.cpanm/ /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/* /tmp/s6-overlay-*.tar.xz*

COPY nginx.conf /etc/nginx/nginx.conf

# Configure nginx and starman with s6
COPY services/starman/run /etc/services.d/starman/run
COPY services/nginx/run /etc/services.d/nginx/run
COPY scripts/ledgersmb_config /etc/s6-overlay/s6-rc.d/ledgersmb_config

RUN chmod +x /etc/services.d/starman/run /etc/services.d/nginx/run /etc/s6-overlay/s6-rc.d/ledgersmb_config/up && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/ledgersmb_config

EXPOSE 80

ENTRYPOINT ["/init"]
