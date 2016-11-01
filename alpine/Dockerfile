FROM alpine:3.4

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -D memcache

ENV MEMCACHED_VERSION 1.4.33
ENV MEMCACHED_SHA1 e343530c55946ccbdd78c488355b02eaf90b3b46

RUN set -x \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		libevent-dev \
		linux-headers \
		make \
		perl \
		tar \
	&& wget -O memcached.tar.gz "http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached \
	&& ./configure \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& cd / && rm -rf /usr/src/memcached \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .memcached-rundeps $runDeps \
	&& apk del .build-deps

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
