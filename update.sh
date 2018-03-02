#!/usr/bin/env bash
set -Eeuo pipefail

versions="$(
	git ls-remote --tags 'https://github.com/memcached/memcached.git' \
		| grep -E '^[0-9]+' \
		| grep -vE -- '-(beta|rc)' \
		| cut -d/ -f3- \
		| cut -d^ -f1 \
		| sort -urV
)"

fullVersion=
sha1=
for version in $versions; do
	if sha1="$(curl -fsSL "https://memcached.org/files/memcached-$version.tar.gz.sha1")" && [ -n "$sha1" ]; then
		sha1="${sha1%% *}"
		fullVersion="$version"
		break
	fi
done
if [ -z "$fullVersion" ] || [ -z "$sha1" ]; then
	echo >&2 "error: could not determine latest release of memcached"
	exit 1
fi

set -x
sed -ri \
	-e 's/^(ENV MEMCACHED_VERSION) .*/\1 '"$fullVersion"'/' \
	-e 's/^(ENV MEMCACHED_SHA1) .*/\1 '"$sha1"'/' \
	*/Dockerfile
