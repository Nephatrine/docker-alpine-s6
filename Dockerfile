FROM alpine:3.13
LABEL maintainer="Daniel Wolf <nephatrine@gmail.com>"

RUN echo "====== INSTALL PACKAGES ======" \
 && apk --update upgrade \
 && apk add \
   bash coreutils file shadow tzdata \
   libressl ca-certificates net-tools \
   logrotate make \
 && rm -rf /var/cache/apk/*

ARG SKALIBS_VERSION=v2.10.0.3
ARG NSSS_VERSION=v0.1.0.1
ARG UTMPS_VERSION=v0.1.0.2
ARG EXECLINE_VERSION=v2.7.0.1
ARG S6_VERSION=v2.10.0.3
ARG S6_PORTABLE_VERSION=v2.2.3.2
ARG S6_LINUX_VERSION=v2.5.1.5
ARG S6_DNS_VERSION=v2.3.5.1
ARG S6_NETWORKING_VERSION=v2.4.1.1
ARG S6_RC_VERSION=v0.5.2.2
ARG S6_INIT_VERSION=v1.0.6.3

ARG ENVDIR_VERSION=v1.0.1-1
ARG S6_PREINIT_VERSION=v1.0.5
ARG S6_OVERLAY_VERSION=v2.2.0.3

RUN echo "====== COMPILE S6 ======" \
 && mkdir /usr/src \
 && apk add --virtual .build-s6 build-base git libressl-dev linux-headers \
 && git -C /usr/src clone -b "$SKALIBS_VERSION" --single-branch --depth=1 https://github.com/skarnet/skalibs.git && cd /usr/src/skalibs \
 && ./configure --disable-ipv6 \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$NSSS_VERSION" --single-branch --depth=1 https://github.com/skarnet/nsss.git && cd /usr/src/nsss \
 && ./configure --enable-libc-includes --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$UTMPS_VERSION" --single-branch --depth=1 https://github.com/skarnet/utmps.git && cd /usr/src/utmps \
 && ./configure --enable-libc-includes --enable-nsss --enable-shared\
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$EXECLINE_VERSION" --single-branch --depth=1 https://github.com/skarnet/execline.git && cd /usr/src/execline \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6.git && cd /usr/src/s6 \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_PORTABLE_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-portable-utils.git && cd /usr/src/s6-portable-utils \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_LINUX_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-linux-utils.git && cd /usr/src/s6-linux-utils \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_DNS_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-dns.git && cd /usr/src/s6-dns \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_NETWORKING_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-networking.git && cd /usr/src/s6-networking \
 && ./configure --enable-nsss --enable-shared --enable-ssl=libressl \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_RC_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-rc.git && cd /usr/src/s6-rc \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_INIT_VERSION" --single-branch --depth=1 https://github.com/skarnet/s6-linux-init.git && cd /usr/src/s6-linux-init \
 && ./configure --enable-nsss --enable-shared --enable-utmps \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$ENVDIR_VERSION" --single-branch --depth=1 https://github.com/just-containers/justc-envdir.git && cd /usr/src/justc-envdir \
 && ./configure --enable-shared --prefix=/usr \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_PREINIT_VERSION" --single-branch --depth=1 https://github.com/just-containers/s6-overlay-preinit.git && cd /usr/src/s6-overlay-preinit \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && git -C /usr/src clone -b "$S6_OVERLAY_VERSION" --single-branch --depth=1 https://github.com/just-containers/s6-overlay.git && cd /usr/src/s6-overlay/builder \
 && egrep 'mkdir -p \$overlaydstpath/|chmod [0-9]+ \$overlaydstpath' build-latest | sed 's/$overlaydstpath/overlay-rootfs/g' > build-here \
 && bash build-here \
 && cd overlay-rootfs \
 && cp -Ran ./* / \
 && cd /usr/src && rm -rf /usr/src/* \
 && apk del --purge .build-s6 && rm -rf /var/cache/apk/*

ENV \
 HOME="/root" \
 PS1="$(whoami)@$(hostname):$(pwd)$ " \
 S6_BEHAVIOUR_IF_STAGE2_FAILS=1 \
 S6_KILL_FINISH_MAXTIME=18000
RUN mkdir -p /mnt/config \
 && useradd -u 1000 -g users -d /mnt/config/home -s /sbin/nologin guardian

COPY override /
ENTRYPOINT ["/init"]