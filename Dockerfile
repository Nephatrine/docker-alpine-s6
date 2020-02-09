FROM alpine:edge
LABEL maintainer="Daniel Wolf <nephatrine@gmail.com>"

RUN echo "====== INSTALL PACKAGES ======" \
 && apk --update upgrade \
 && apk add \
   bash coreutils file shadow tzdata \
   libressl ca-certificates net-tools \
   logrotate make \
 && rm -rf /var/cache/apk/*

RUN echo "====== COMPILE S6 ======" \
 && mkdir /usr/src \
 && apk add --virtual .build-s6 build-base git libressl-dev \
 && cd /usr/src \
 && git clone https://github.com/skarnet/skalibs.git && cd skalibs \
 && ./configure --disable-ipv6 \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/nsss.git && cd nsss \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/execline.git && cd execline \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6.git && cd s6 \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-dns.git && cd s6-dns \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-networking.git && cd s6-networking \
 && ./configure --enable-nsss --enable-shared --enable-ssl=libressl \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-rc.git && cd s6-rc \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-portable-utils.git && cd s6-portable-utils \
 && ./configure --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/skarnet/s6-linux-utils.git && cd s6-linux-utils \
 && ./configure --enable-nsss --enable-shared \
 && make -j4 strip && make install \
 && cd /usr/src \
 && git clone https://github.com/just-containers/s6-overlay.git && cd s6-overlay/builder \
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