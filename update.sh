#!/bin/bash
set -e

fullVersion="$(curl -sSL 'http://memcached.org/files/' | grep -E '<a href="memcached-[0-9.]+\.tar\.gz"' | sed -r 's!.*<a href="memcached-([0-9.]+)\.tar\.gz".*!\1!' | sort -V | tail -1)"

sha1="$(curl -sSL "http://memcached.org/files/memcached-$fullVersion.tar.gz.sha1" | cut -d' ' -f1)"

set -x
sed -ri '
	s/^(ENV MEMCACHED_VERSION) .*/\1 '"$fullVersion"'/;
	s/^(ENV MEMCACHED_SHA1) .*/\1 '"$sha1"'/;
' Dockerfile
