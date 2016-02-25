#!/bin/sh

PATH=/sbin:/usr/bin:$PATH
DEST=8.8.8.8

DEV=br-rid
ip -4 addr show dev $DEV 2>/dev/null 1>&2
if [ $? -ne 0 ]; then
    DEV=br-ffgt
fi
ip -4 addr show dev $DEV 2>/dev/null 1>&2
if [ $? -ne 0 ]; then
    echo "DEFGW CRITICAL: can not find suitable interface"
    exit 2
fi

SRCIP=`ip -4 addr show dev $DEV|awk '/inet/ {ip=$2; gsub("/.*$", "", ip); print ip;}'`

ping -q -c 5 -I $SRCIP $DEST 2>/dev/null >/tmp/$$.out
RC=$?
RESSTR="`grep </tmp/$$.out 'packets transmitted'`"
if [ $RC -eq 0 ]; then
    echo "DEFGW OK: $RESSTR"
else
    echo "DEFGW CRITICAL: $RESSTR"
fi
/bin/rm /tmp/$$.out
exit $RC
