FROM alpine:3.10

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -g 11211 memcache && adduser -D -u 11211 -G memcache memcache

# ensure SASL's "libplain.so" is installed as per https://github.com/memcached/memcached/wiki/SASLHowto
RUN apk add --no-cache cyrus-sasl-plain

ENV MEMCACHED_VERSION 1.5.16
ENV MEMCACHED_SHA1 06a9661638cb20232d0ccea088f52ca10b959968

RUN set -x \
	\
	&& apk add --no-cache --virtual .build-deps \
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
		perl \
		perl-utils \
		tar \
		wget \
	\
	&& wget -O memcached.tar.gz "https://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	\
	&& cd /usr/src/memcached \
	\
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& enableExtstore="$( \
# https://github.com/docker-library/memcached/pull/38
		case "$gnuArch" in \
# https://github.com/memcached/memcached/issues/381 "--enable-extstore on s390x (IBM System Z mainframe architecture) fails tests"
			s390x-*) ;; \
			*) echo '--enable-extstore' ;; \
		esac \
	)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-sasl \
		--enable-sasl-pwdb \
		$enableExtstore \
	&& make -j "$(nproc)" \
	\
# TODO https://github.com/memcached/memcached/issues/382 "t/chunked-extstore.t is flaky on arm32v6"
	&& make test \
	&& make install \
	\
	&& cd / && rm -rf /usr/src/memcached \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --virtual .memcached-rundeps $runDeps \
	&& apk del .build-deps \
	\
	&& memcached -V

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
