#!/bin/bash

TODO="$(/bin/ls -l /var/local/rrd-traffic/*.data 2>/dev/null | /usr/bin/wc -l
)"
if [ "${TODO}" != "0" ]; then
  for i in /var/local/rrd-traffic/*.data
  do
    echo "Processing $i ..."
    /root/rrd_traffic_slave.pl --slavedata $i
    #/home/ffgt/fastd-summary-rrd.sh 2>&1 >/dev/null
    #/home/ffgt/uplink-summary-rrd.sh 2>&1 >/dev/null
    chown www-data:www-data -R /var/www/rrd-traffic/images
  done
fi
