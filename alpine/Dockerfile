FROM alpine:3.3

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -D memcache

ENV MEMCACHED_VERSION 1.4.25
ENV MEMCACHED_SHA1 7fd0ba9283c61204f196638ecf2e9295688b2314
ENV MEMCACHED_SHA256 f058437b3c224d321919a9a6bb4e3eedb2312ed718c0caf087ff2f04ab795dda

# https://github.com/memcached/memcached/issues/138
RUN set -x \
	&& apk add --no-cache --virtual .build-deps \
		curl \
		gcc \
		libc-dev \
		libevent-dev \
		linux-headers \
		make \
		perl \
	&& curl -SL "http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" -o memcached.tar.gz \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& echo "$MEMCACHED_SHA256  memcached.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/src \
	&& tar -xzf memcached.tar.gz -C /usr/src \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached-$MEMCACHED_VERSION \
	&& sed -i -e 's:#include <sys/signal.h>:#include <signal.h>:' *.c \
	&& ./configure \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& cd / && rm -rf /usr/src/memcached-* \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .memcached-rundeps $runDeps \
	&& apk del .build-deps

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
