FROM wb253/alpine:latest

RUN addgroup -S redis && adduser -S -G redis redis

RUN apk add --no-cache \
		'su-exec>=0.2' \
		tzdata

ENV REDIS_VERSION 5.0.4
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-5.0.4.tar.gz
ENV REDIS_DOWNLOAD_SHA 3ce9ceff5a23f60913e1573f6dfcd4aa53b42d4a2789e28fa53ec2bd28c987dd

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		gcc \
                bash \
		linux-headers \
		make \
		musl-dev \
                bash \
                tree \
                tzdata \
                && cp -r -f /usr/share/zoneinfo/Hongkong /etc/localtime \
	; \
	\
	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
	\
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	\
	rm -r /usr/src/redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .redis-rundeps $runDeps; \
	apk del .build-deps; \
	\
	redis-server --version

RUN mkdir /data && chown redis:redis /data
VOLUME /data
WORKDIR /data

COPY docker-entrypoint.sh /usr/local/bin/
COPY redis.conf /etc/redis.conf
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 6379
CMD ["redis-server","/etc/redis.conf"]