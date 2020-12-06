#!/bin/sh

set -e -u

while read -r route
do
    ip route add "$route" "$@"
done
