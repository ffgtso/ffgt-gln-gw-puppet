#!/bin/bash

for i in /data2/rrd_traffic/*.data
do
    echo "Processing $i ..."
    /root/rrd_traffic_slave.pl --slavedata $i
    /home/ffgt/fastd-summary-rrd.sh 2>&1 >/dev/null
    /home/ffgt/uplink-summary-rrd.sh 2>&1 >/dev/null
    chown www-data:www-data -R /data2/www-sites/ffgt/noc/rrd
done
