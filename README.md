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
