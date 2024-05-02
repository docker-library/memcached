#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.20

# The global SOURCE_DATE_EPOCH is consumed by commands that are not associated with a source artifact.
# This is not propagated from --build-arg: https://github.com/moby/buildkit/issues/4576#issuecomment-2159501282
ENV SOURCE_DATE_EPOCH 0

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# On Debian, useradd recognizes SOURCE_DATE_EPOCH to reproduce the "lastchanged" field in /etc/shadow.
RUN set -eux; \
	addgroup -g 11211 memcache; \
	adduser -D -u 11211 -G memcache memcache

# ensure SASL's "libplain.so" is installed as per https://github.com/memcached/memcached/wiki/SASLHowto
RUN apk add --no-cache libsasl

ENV MEMCACHED_VERSION 1.6.31
ENV MEMCACHED_URL https://memcached.org/files/memcached-1.6.31.tar.gz
ENV MEMCACHED_SHA1 85e2cb9520beba71d7fc69f5717208a57facde28

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps=0 \
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
	; \
	\
	wget -O memcached.tar.gz "$MEMCACHED_URL"; \
	echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c -; \
	mkdir -p /usr/src/memcached; \
	tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1; \
	rm memcached.tar.gz; \
	\
	cd /usr/src/memcached; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	SOURCE_DATE_EPOCH="$(find . -type f -exec stat -c '%Y' {} + | sort -nr | head -n1)"; \
	export SOURCE_DATE_EPOCH; \
# for logging validation/edification
	date --date "@$SOURCE_DATE_EPOCH" --rfc-2822; \
	./configure \
		--build="$gnuArch" \
		--enable-extstore \
		--enable-sasl \
		--enable-sasl-pwdb \
		--enable-tls \
	; \
	nproc="$(nproc)"; \
	make -j "$nproc"; \
	\
	make test PARALLEL="$nproc"; \
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
	apk add --no-network --virtual .memcached-rundeps=0 $runDeps; \
	apk del --no-network .build-deps; \
	\
	memcached -V ;\
# clean up for reproducibility
	rm -rf /tmp/*

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
