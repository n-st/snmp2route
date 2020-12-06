#!/bin/sh

set -e -u

if ! [ $# -eq 1 ]
then
    printf 'Usage: %s <SNMP hostname/IP>\n' "$0" 1>&2
    exit 1
fi

SNMP_HOST="$1"

tempprefix="$(basename "$0")"
tempdir="$(mktemp -d -t "${tempprefix}.XXXXXXXXXX")"

trap 'rm -rf "$tempdir"' EXIT

cd "$tempdir" || exit 1

if ! snmpwalk -v2c -c public -On -Oe "$SNMP_HOST" .1.3.6.1.2.1.4.24.4.1.16 > ipCidrRouteStatus.txt
then
    printf 'snmpwalk failed. Aborting.\n' 1>&2
    exit 1
fi

orig_linecount=$(grep -c . ipCidrRouteStatus.txt)

# example line:
# .1.3.6.1.2.1.4.24.4.1.16.10.43.0.0.255.255.0.0.0.44.225.43.1 = INTEGER: 1

# regex: '^\.1\.3\.6\.1\.2\.1\.4\.24\.4\.1\.16\.
#           \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.  # ipCidrRouteDest
#           \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.  # ipCidrRouteMask
#           [0-9]\+\.  # ipCidrRouteTos
#           \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)  # ipCidrRouteNextHop
#            = INTEGER: 1$'

# sed command:
# - don't print lines by default
# - only operate on lines that match the regex (and already fill capture groups while matching)
#   - replace the line with "\1/\2", i.e. "RouteDest/RouteMask"
#   - print the line
sed -n '/^\.1\.3\.6\.1\.2\.1\.4\.24\.4\.1\.16\.\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.[0-9]\+\.\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\) = INTEGER: 1/{s@@\1/\2@;p}' ipCidrRouteStatus.txt > routes.txt

new_linecount=$(grep -c . routes.txt)

if [ "$orig_linecount" -ne "$new_linecount" ]
then
    printf 'snmpwalk output contained lines that could not be parsed. Aborting.\n' 1>&2
    exit 1
fi

cat routes.txt
