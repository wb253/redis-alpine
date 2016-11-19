FROM wb253/lpine
MAINTAINER wangbin <wangbin253@gmail.com>

RUN apk add --no-cache \
        redis \
        nmap-ncat && \

    # Remove default config
    rm /etc/redis.conf

COPY rootfs /
