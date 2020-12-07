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


old_tablenum=""

# get currently used table number
if [ -z "$(ip rule show table 44)" ]
# set new table number
then
    tablenum=44
    old_tablenum=45
else
    tablenum=45
    old_tablenum=44
fi

ip route show table "$old_tablenum" | sort > "$tempdir/routes-before.txt"

# add routes to new table
./snmp2route2iproute2.sh \
    "$SNMP_HOST" \
    "$@" table "$tablenum"

ip route show table "$tablenum" | sort > "$tempdir/routes-after.txt"

# add rule for new table
ip rule add table "$tablenum"

if [ -n "$(ip rule show table "$old_tablenum")" ]
then
    # delete rule for old table
    ip rule del table "$old_tablenum"

    # flush old table
    ip route flush table "$old_tablenum"
fi

lines_added="$(comm -13 "$tempdir/routes-before.txt" "$tempdir/routes-after.txt")"
lines_deleted="$(comm -23 "$tempdir/routes-before.txt" "$tempdir/routes-after.txt")"
num_added="$(printf '%s\n' "$lines_added" | grep -c . || true)"
num_deleted="$(printf '%s\n' "$lines_deleted" | grep -c . || true)"
num_total="$(grep -c . "$tempdir/routes-after.txt" || true)"

printf 'Routes: %d added, %d deleted, now %d total\n' "$num_added" "$num_deleted" "$num_total"

if [ "$num_added" -ne 0 ]
then
    printf '\n'
    printf 'Added:\n%s\n' "$lines_added"
fi

if [ "$num_deleted" -ne 0 ]
then
    printf '\n'
    printf 'Deleted:\n%s\n' "$lines_deleted"
fi
