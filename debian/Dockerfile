FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd --system --gid 11211 memcache && useradd --system --gid memcache --uid 11211 memcache

ENV MEMCACHED_VERSION 1.5.13
ENV MEMCACHED_SHA1 f0ddd566a55fdc5397d458cf3b3806b5cb48bb18

RUN set -x \
	\
	&& buildDeps=' \
		ca-certificates \
		dpkg-dev \
		gcc \
		libc6-dev \
		libevent-dev \
		libsasl2-dev \
		make \
		perl \
		wget \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O memcached.tar.gz "https://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	\
	&& cd /usr/src/memcached \
	\
# https://github.com/memcached/memcached/pull/480 (hopefully to be removed in 1.5.14)
	&& wget -O wait_ext_flush.patch 'https://github.com/memcached/memcached/pull/480.patch' \
	&& patch -p1 --input=wait_ext_flush.patch \
	&& rm wait_ext_flush.patch \
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
		$enableExtstore \
	&& make -j "$(nproc)" \
	\
# TODO https://github.com/memcached/memcached/issues/382 "t/chunked-extstore.t is flaky on arm32v6"
	&& make test \
	&& make install \
	\
	&& cd / && rm -rf /usr/src/memcached \
	\
	&& apt-mark manual \
		libevent-2.0-5 \
		libsasl2-2 \
	&& apt-get purge -y --auto-remove $buildDeps \
	\
	&& memcached -V

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
