#!/usr/bin/env bash
set -Eeuo pipefail

# we will support at most two entries in each of these lists, and both should be in descending order
supportedDebianSuites=(
	bookworm
)
supportedAlpineVersions=(
	3.18
)
defaultDebianSuite="${supportedDebianSuites[0]}"
declare -A debianSuites=(
	#[7.2]='3.17'
)
defaultAlpineVersion="${supportedAlpineVersions[0]}"
declare -A alpineVersions=(
	#[14]='3.16'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
	json='{}'
else
	json="$(< versions.json)"
fi
versions=( "${versions[@]%/}" )

packagesBase='https://github.com/memcached/memcached.git'

packages=()

fetch_package_list() {
	local -; set +x # make sure running with "set -x" doesn't spam the terminal with the raw package lists

	if [ "${#packages[@]}" -le 0 ]; then
		packages=( $(
			git ls-remote --tags 'https://github.com/memcached/memcached.git' \
			| cut -d/ -f3- \
			| cut -d^ -f1 \
			| grep -E '^[0-9]+' \
			| grep -vE -- '-(beta|rc)' \
			| sort -urV
		) )
	fi
}

get_version() {
	local version="$1"; shift

	versionPattern="^${version/\./\\.}\.[0-9]*$"
	filteredVersions=($(printf "%s\n" "${packages[@]}" | grep -E "${versionPattern}"))
	fullVersion="${filteredVersions[0]}"

	downloadUrl="https://memcached.org/files/memcached-$fullVersion.tar.gz"

	shaHash="$(curl -fsSL "${downloadUrl}.sha1")"

	if [ -n "$shaHash" ]; then
		shaHash="${shaHash%% *}"
	fi
}

for version in "${versions[@]}"; do
	export version

	versionAlpineVersion="${alpineVersions[$version]:-$defaultAlpineVersion}"
	versionDebianSuite="${debianSuites[$version]:-$defaultDebianSuite}"
	export versionAlpineVersion versionDebianSuite

	doc="$(jq -nc '{
		alpine: env.versionAlpineVersion,
		debian: env.versionDebianSuite,
	}')"

	fetch_package_list
	get_version "$version"

	if [ -z "$fullVersion" ] || [ -z "$shaHash" ]; then
		echo >&2 "error: could not determine latest release of memcached"
		exit 1
	fi

	for suite in "${supportedDebianSuites[@]}"; do
		export suite
		doc="$(jq <<<"$doc" -c '
			.variants += [ env.suite ]
		')"
	done

	for alpineVersion in "${supportedAlpineVersions[@]}"; do
		doc="$(jq <<<"$doc" -c --arg v "$alpineVersion" '
			.variants += [ "alpine" + $v ]
		')"
	done

	echo "$version: $fullVersion"

	export fullVersion shaHash downloadUrl
	json="$(jq <<<"$json" -c --argjson doc "$doc" '
		.[env.version] = ($doc + {
			version: env.fullVersion,
			downloadUrl: env.downloadUrl,
			sha1: env.shaHash
		})
	')"
done

jq <<<"$json" -S . > versions.json
