#!/bin/sh
set -xe

if [ "$WAIT_FOR_ADDRESS" ]; then
	WAIT_FOR_TIMEOUT=${WAIT_FOR_TIMEOUT:-60}

	## Wait before start daemon
	wait-for -t "$WAIT_FOR_TIMEOUT" "$WAIT_FOR_ADDRESS"
fi

## Start PHP-FPM daemon
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"
