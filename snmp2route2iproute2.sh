#!/bin/sh

set -e -u

if ! [ $# -ge 1 ]
then
    printf 'Usage: %s <SNMP hostname/IP> [iproute2 options ...]\n' "$0" 1>&2
    exit 1
fi

SNMP_HOST="$1"
shift

tempprefix="$(basename "$0")"
tempdir="$(mktemp -d -t "${tempprefix}.XXXXXXXXXX")"

trap 'rm -rf "$tempdir"' EXIT

cd "$(dirname "$(readlink -f "$0")")" || exit

if ! ./snmp2route.sh "$SNMP_HOST" > routes.txt
then
    printf 'snmp2route failed. Aborting.\n' 1>&2
    exit 1
fi

grep '^44\.' routes.txt | ./route2iproute2.sh "$@"
