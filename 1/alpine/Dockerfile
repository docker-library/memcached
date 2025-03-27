#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.21

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
	addgroup -g 11211 memcache; \
	adduser -D -u 11211 -G memcache memcache

# ensure SASL's "libplain.so" is installed as per https://github.com/memcached/memcached/wiki/SASLHowto
RUN apk add --no-cache libsasl

ENV MEMCACHED_VERSION 1.6.38
ENV MEMCACHED_URL https://memcached.org/files/memcached-1.6.38.tar.gz
ENV MEMCACHED_SHA1 2d132faaf4d4ffa4c1b5f55b2f09056a0e9181dd

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		ca-certificates \
		coreutils \
		cyrus-sasl-dev \
		dpkg-dev dpkg \
		gcc \
		libc-dev \
		libevent-dev \
		linux-headers \
		make \
		openssl \
		openssl-dev \
		perl \
		perl-io-socket-ssl \
		perl-utils \
# temporary, see below
		patch \
	; \
	\
	wget -O memcached.tar.gz "$MEMCACHED_URL"; \
	echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c -; \
	mkdir -p /usr/src/memcached; \
	tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1; \
	rm memcached.tar.gz; \
	\
# https://github.com/memcached/memcached/issues/1220
# https://github.com/memcached/memcached/pull/1221
	wget -O memcached-time-overflow.patch 'https://github.com/tianon/memcached/commit/8d4e02984661a3a26decc5a45d62a9eeaaf72986.patch?full_index=1'; \
	echo '59f068d1fe4819ec65ec8c7adc8c5ecf8a7753ba5c6e5a17e5ba42c9946074a2 *memcached-time-overflow.patch' | sha256sum -c -; \
	patch --input="$PWD/memcached-time-overflow.patch" --strip=1 --directory=/usr/src/memcached; \
	rm memcached-time-overflow.patch; \
	\
	cd /usr/src/memcached; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--enable-extstore \
		--enable-proxy \
		--enable-sasl \
		--enable-sasl-pwdb \
		--enable-tls \
	; \
	nproc="$(nproc)"; \
	make -j "$nproc"; \
	\
# try the tests in parallel first, but many of them are resource-intensive, so fall back to serial
	make test PARALLEL="$nproc" || make test; \
	\
	make install; \
	\
	cd /; \
	rm -rf /usr/src/memcached; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .memcached-rundeps $runDeps; \
	apk del --no-network .build-deps; \
	\
	memcached -V

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
