#!/bin/sh

set -e -u

if ! [ $# -ge 1 ]
then
    printf 'Usage: %s <SNMP hostname/IP> [iproute2 options ...]\n' "$0" 1>&2
    exit 1
fi

SNMP_HOST="$1"
shift

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

# add routes to new table
./snmp2route2iproute2.sh \
    "$SNMP_HOST" \
    "$@" table "$tablenum"

# add rule for new table
ip rule add table "$tablenum"

if [ -n "$(ip rule show table "$old_tablenum")" ]
then
    # delete rule for old table
    ip rule del table "$old_tablenum"

    # flush old table
    ip route flush table "$old_tablenum"
fi
