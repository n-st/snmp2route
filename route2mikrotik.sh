#!/bin/sh

set -e -u

gateway="$1"

netmask_to_prefixlen () {
    # based on https://stackoverflow.com/a/50419919/
    octets="$(printf '%s\n' "$1" | tr '.' ' ')" # POSIX doesn't have ${str//search/replace}
    c=0

    # shellcheck disable=SC2086 # word splitting is intentional here
    x="0$( printf '%o' $octets )"

    while [ "$x" -gt 0 ]; do
        c=$((c+(x%2)))
        x=$((x/2))
    done

    echo $c
}


# Context switches like '/ip route' don't seem to stick when piped directly
# into an SSH session, so we will just use explicit context identifiers (/ip
# route add ...) for each command.

while read -r route
do
    address="${route%%/*}"
    netmask="${route##*/}"
    prefixlen="$(netmask_to_prefixlen "$netmask")"
    printf '%s\n' "/ip route add dst-address=$address/$prefixlen gateway=$gateway comment=new-autogenerated-from-snmp"
done

# shellcheck disable=SC2016 # $r is a RouterOS variable and should be preserved literally
{
    printf '%s\n' ':foreach r in=[/ip route find comment=autogenerated-from-snmp] do={/ip route remove $r}'
    printf '%s\n' ':foreach r in=[/ip route find comment=new-autogenerated-from-snmp] do={/ip route set comment=autogenerated-from-snmp $r}'
}
