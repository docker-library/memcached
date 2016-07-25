#!/bin/sh
set -e

MEMORY=${MEMCACHED_MEMORY:-64}
CONNECTIONS=${MEMCACHED_CONNECTIONS:-1024}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- memcached -m ${MEMORY} -c ${CONNECTIONS} "$@"
else
	set -- memcached -m ${MEMORY} -c ${CONNECTIONS}
fi

exec "$@"
