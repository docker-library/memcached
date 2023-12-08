#!/usr/bin/env bash
set -Eeuo pipefail

alpine="$(
	bashbrew cat --format '{{ .TagEntry.Tags | join "\n" }}' https://github.com/docker-library/official-images/raw/HEAD/library/alpine:latest \
		| grep -E '^[0-9]+[.][0-9]+$'
)"
[ "$(wc -l <<<"$alpine")" = 1 ]
export alpine

debian="$(
	bashbrew cat --format '{{ .TagEntry.Tags | join "\n" }}' https://github.com/docker-library/official-images/raw/HEAD/library/debian:latest \
		| grep -vE '^latest$|[0-9.-]' \
		| head -1
)"
[ "$(wc -l <<<"$debian")" = 1 ]
export debian

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
	json='{}'
else
	json="$(< versions.json)"
fi
versions=( "${versions[@]%/}" )

possibles="$(
	git ls-remote --tags 'https://github.com/memcached/memcached.git' \
		| cut -d/ -f3- \
		| cut -d^ -f1 \
		| grep -E '^[0-9]+' \
		| grep -vE -- '-(beta|rc)' \
		| sort -urV
)"

for version in "${versions[@]}"; do
	export version

	versionPossibles="$(grep <<<"$possibles" -E "^$version([.-]|\$)")"

	fullVersion=
	sha1=
	url=
	for possible in $versionPossibles; do
		url="https://memcached.org/files/memcached-$possible.tar.gz"
		if sha1="$(curl -fsSL "$url.sha1")" && [ -n "$sha1" ]; then
			sha1="${sha1%% *}"
			fullVersion="$possible"
			break
		fi
	done
	if [ -z "$fullVersion" ]; then
		echo >&2 "error: could not determine latest release for $version"
		exit 1
	fi
	[ -n "$sha1" ]
	[ -n "$url" ]

	echo "$version: $fullVersion"

	export fullVersion sha1 url
	json="$(jq <<<"$json" -c '
		.[env.version] = {
			version: env.fullVersion,
			url: env.url,
			sha1: env.sha1,
			alpine: { version: env.alpine },
			debian: { version: env.debian },
		}
	')"
done

jq <<<"$json" . > versions.json
