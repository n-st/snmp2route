# snmp2route: Obtain parsable routing tables via SNMP

## snmp2route.sh

This script querys a host via SNMP and prints its entire routing table in
parsable format for further use.

Requires a POSIX-compliant shell and [`snmpwalk` from the Net-SNMP
suite](http://www.net-snmp.org/docs/man/snmpwalk.html).

Example:

    $ ./snmp2route.sh 44.149.43.1
    0.0.0.0/0.0.0.0
    10.43.0.0/255.255.0.0
    44.0.0.1/255.255.255.255
    […]
    44.225.184.128/255.255.255.192
    44.225.185.192/255.255.255.192
    44.225.188.0/255.255.255.224

## route2iproute2.sh

This script reads routes from stdin, route options from its parameters, and
adds routes to the system routing tables accordingly.

Example:

    # echo '44.225.188.0/255.255.255.224' | ./route2iproute2.sh via 10.123.0.1 table 123
    $ ip route show table 123
    44.225.188.0/27 via 10.123.0.1

## snmp2route2iproute2.sh

This script combines `snmp2route.sh` and `route2iproute2.sh` to automatically
add SNMP-obtained routes to the system routing table.

**Note:** This script contains a hardcoded filter to only accept routes to
prefixes under 44.0.0.0/8.

Example:

    # ./snmp2route2iproute2.sh 44.149.43.1 via 10.123.0.1
    $ ip route show
    44.225.188.0/27 via 10.123.0.1
    […]

## regenerate-iproute2.sh

This script uses `snmp2route2iproute2.sh` and the iproute2 routing tables `44`
and `45` to automatically regenerate and refresh the SNMP-obtained routes:

It …

0. obtains the current remote routing table via SNMP,
0. adds it to an unused separate table (44 or 45, whichever is free),
0. enables use of that table system-wide,
0. disables use of the previously used table (45 or 44, if one was in use),
0. empties the previously used table.

Example:

    # ./regenerate-iproute2.sh 44.149.43.1 via 10.123.0.1
    Routes: 3 added, 0 deleted, now 2695 total
    
    Added:
    44.2.10.0/29 via 10.123.0.1
    44.2.2.0/24 via 10.123.0.1
    44.2.7.24/29 via 10.123.0.1
    
    $ ip route show table 44
    44.225.188.0/27 via 10.123.0.1
    […]

