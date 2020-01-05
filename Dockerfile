FROM alpine:3.11
LABEL maintainer="Daniel Wolf <nephatrine@gmail.com>"

RUN echo "====== INSTALL PACKAGES ======" \
 && apk --update upgrade \
 && apk add \
   bash coreutils file shadow tzdata \
   libressl ca-certificates net-tools \
   logrotate make \
 && rm -rf /var/cache/apk/*

ARG SKALIBS_VERSION=v2.9.1.0
ARG NSSS_VERSION=v0.0.2.1
ARG EXECLINE_VERSION=v2.5.3.0
ARG S6_VERSION=v2.9.0.1
ARG S6_DNS_VERSION=v2.3.1.1
ARG S6_NETWORKING_VERSION=v2.3.1.1
ARG S6_RC_VERSION=v0.5.1.1
ARG S6_PORTABLE_VERSION=v2.2.2.1
ARG S6_LINUX_VERSION=v2.5.1.1
ARG S6_OVERLAY_VERSION=v1.22.1.0

RUN echo "====== COMPILE S6 ======" \
 && mkdir /usr/src \
 && apk add --virtual .build-s6 build-base git libressl-dev \
 && cd /usr/src \
 && git clone https://github.com/skarnet/skalibs.git && cd skalibs \
 && git fetch && git fetch --tags \
 && git checkout "$SKALIBS_VERSION" \
 && ./configure --disable-ipv6 \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/nsss.git && cd nsss \
 && git fetch && git fetch --tags \
 && git checkout "$NSSS_VERSION" \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/execline.git && cd execline \
 && git fetch && git fetch --tags \
 && git checkout "$EXECLINE_VERSION" \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6.git && cd s6 \
 && git fetch && git fetch --tags \
 && git checkout "$S6_VERSION" \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-dns.git && cd s6-dns \
 && git fetch && git fetch --tags \
 && git checkout "$S6_DNS_VERSION" \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-networking.git && cd s6-networking \
 && git fetch && git fetch --tags \
 && git checkout "$S6_NETWORKING_VERSION" \
 && ./configure --enable-nsss --enable-shared --enable-ssl=libressl \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-rc.git && cd s6-rc \
 && git fetch && git fetch --tags \
 && git checkout "$S6_RC_VERSION" \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-portable-utils.git && cd s6-portable-utils \
 && git fetch && git fetch --tags \
 && git checkout "$S6_PORTABLE_VERSION" \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-linux-utils.git && cd s6-linux-utils \
 && git fetch && git fetch --tags \
 && git checkout "$S6_LINUX_VERSION" \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/just-containers/s6-overlay.git && cd s6-overlay/builder \
 && git fetch && git fetch --tags \
 && git checkout "$S6_OVERLAY_VERSION" \
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
