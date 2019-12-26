FROM alpine:edge
LABEL maintainer="Daniel Wolf <nephatrine@gmail.com>"

ENV \
 HOME="/root" \
 PS1="$(whoami)@$(hostname):$(pwd)$ " \
 S6_BEHAVIOUR_IF_STAGE2_FAILS=1 \
 S6_KILL_FINISH_MAXTIME=18000

RUN echo "====== INSTALL PACKAGES ======" \
 && apk --update upgrade \
 && apk add \
   bash \
   ca-certificates \
   coreutils \
   file \
   libressl \
   logrotate \
   make \
   net-tools \
   shadow \
   tzdata \
 && apk add --virtual .build-alpine-s6 \
   build-base \
   git \
   libressl-dev \
 \
 && echo "====== CONFIGURE SYSTEM ======" \
 && mkdir -p /mnt/config /usr/src \
 && useradd -u 1000 -g users -d /mnt/config/home -s /sbin/nologin guardian \
 \
 && echo "====== COMPILE SKALIBS ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/skalibs.git \
 && cd skalibs \
 && ./configure --disable-ipv6 \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE NSSS ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/nsss.git \
 && cd nsss \
 && ./configure --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE EXECLINE ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/execline.git \
 && cd execline \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6 ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6.git \
 && cd s6 \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6-DNS ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-dns.git \
 && cd s6-dns \
 && ./configure --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6-NETWORKING ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-networking.git \
 && cd s6-networking \
 && ./configure --enable-nsss --enable-shared --enable-ssl=libressl \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6-RC ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-rc.git \
 && cd s6-rc \
 && ./configure --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6-PORTABLE-UTILS ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-portable-utils.git \
 && cd s6-portable-utils \
 && ./configure --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== COMPILE S6-LINUX-UTILS ======" \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-linux-utils.git \
 && cd s6-linux-utils \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip \
 && make install \
 \
 && echo "====== INSTALL S6-OVERLAY ======" \
 && cd /usr/src \
 && git clone https://github.com/just-containers/s6-overlay.git \
 && cd s6-overlay/builder \
 && egrep 'mkdir -p \$overlaydstpath/|chmod [0-9]+ \$overlaydstpath' build-latest | sed 's/$overlaydstpath/overlay-rootfs/g' > build-here \
 && bash build-here \
 && cd overlay-rootfs \
 && cp -Ran ./* / \
 \
 && echo "====== CLEANUP ======" \
 && cd /usr/src \
 && apk del --purge .build-alpine-s6 \
 && rm -rf /tmp/* /usr/src/* /var/cache/apk/*

COPY override /
ENTRYPOINT ["/init"]
