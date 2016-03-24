#!/bin/sh
set -e

# first check if we're passing flags, if so
# prepend with memcached
case "$1" in
-*) set -- memcached "$@";;
esac

exec "$@"
