#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:bookworm-slim

# The global SOURCE_DATE_EPOCH is consumed by commands that are not associated with a source artifact.
# This is not propagated from --build-arg: https://github.com/moby/buildkit/issues/4576#issuecomment-2159501282
ENV SOURCE_DATE_EPOCH 0

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# On Debian, useradd recognizes SOURCE_DATE_EPOCH to reproduce the "lastchanged" field in /etc/shadow.
RUN set -eux; \
	groupadd --system --gid 11211 memcache; \
	useradd --system --gid memcache --uid 11211 memcache

# ensure SASL's "libplain.so" is installed as per https://github.com/memcached/memcached/wiki/SASLHowto
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libsasl2-modules \
	; \
	rm -rf /var/lib/apt/lists/*; \
# clean up for reproducibility
	rm -rf /var/log/* /var/cache/ldconfig/aux-cache

ENV MEMCACHED_VERSION 1.6.31
ENV MEMCACHED_URL https://memcached.org/files/memcached-1.6.31.tar.gz
ENV MEMCACHED_SHA1 85e2cb9520beba71d7fc69f5717208a57facde28

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		dpkg-dev \
		gcc \
		libc6-dev \
		libevent-dev \
		libio-socket-ssl-perl \
		libsasl2-dev \
		libssl-dev \
		make \
		perl \
		wget \
	; \
	rm -rf /var/lib/apt/lists/*; \
# clean up for reproducibility
	rm -rf /var/log/* /var/cache/ldconfig/aux-cache; \
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
# see https://github.com/docker-library/memcached/pull/54#issuecomment-562797748 and https://bugs.debian.org/927461 for why we have to munge openssl.cnf
	sed -i.bak 's/SECLEVEL=2/SECLEVEL=1/g' /etc/ssl/openssl.cnf; \
	make test PARALLEL="$nproc"; \
	mv /etc/ssl/openssl.cnf.bak /etc/ssl/openssl.cnf; \
	\
	make install; \
	\
	cd /; \
	rm -rf /usr/src/memcached; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
# clean up for reproducibility
	rm -rf /var/log/* /var/cache/ldconfig/aux-cache; \
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
