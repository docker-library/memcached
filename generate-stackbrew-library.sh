#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

url='git://github.com/docker-library/memcached'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for dockerfile in Dockerfile */Dockerfile; do
	variant="${dockerfile%/*}"
	if [ "$variant" = "$dockerfile" ]; then
		variant=
	fi
	commit="$(git log -1 --format='format:%H' -- "$dockerfile" $(awk 'toupper($1) == "COPY" { for (i = 2; i < NF; i++) { print $i } }' "$dockerfile"))"
	fullVersion="$(grep -m1 'ENV MEMCACHED_VERSION ' "$dockerfile" | cut -d' ' -f3)"

	versionAliases=()
	while [ "${fullVersion%.*}" != "$fullVersion" ]; do
		versionAliases+=( ${fullVersion}${variant:+-$variant} )
		fullVersion="${fullVersion%.*}"
	done
	versionAliases+=( ${fullVersion}${variant:+-$variant} ${variant:-latest} )

	echo
	for va in "${versionAliases[@]}"; do
		echo "${va}: ${url}@${commit}"
	done
done
