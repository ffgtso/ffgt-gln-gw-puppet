#!/bin/bash
#
# Expects periodic call back from the client.
# a) If client is unknown (no /tmp/l2tp-${MAC}* files, prepare tunnel and reply with session-id, port, local- and remote IP
# b) If client is known but remote-ip differs (/tmp/l2tp-${MAC}.lastip): take tunnel down and bring it up again to the new destination
# c) If client hasn't connected for 5 Minutes, tear down local end of the tunnel, wipe /tmp/l2tp-${MAC}*
#
if [ $# -ne 3 -a $# -ne 1 ]; then
  logger "$0: ERROR: Too few arguments ($#)"
  echo "NAK"
  exit 0
fi

MAC="$1"

if [ "${MAC}" == "cleanup" ]; then
  for file in $(find /tmp -cmin +15 -name l2tp-????????????.lastip)
  do
    peerfiles="$(basename $file .lastip)"
    delpattern="${peerfiles}*"
    if [ -e /tmp/${peerfiles}.down ]; then
      logger "sudo /tmp/${peerfiles}.down # CLEANUP"
      sudo /tmp/${peerfiles}.down
    fi
    touch /tmp/${peerfiles}.delete
    /bin/rm /tmp/${delpattern}
  done
  exit 0
fi

RIP="$2"
RPORT="$3"
#LIP="$(ip -o -4 addr show dev ens3 | awk '{printf("%s", substr($4, 1, index($4, "/")-1));}')"
LIP="192.251.226.19"
LIF=ens3
PORT=10000
SID="$(echo $MAC | awk -Wposix '{printf("%d", "0x" substr($1, 9,4));}')"
BRIP6="$(ip -o -6 addr show dev br-l2tp | awk '{printf("%s", substr($4, 1, index($4, "/")-1));}')"

LASTIP="127.0.0.1"
if [ -e /tmp/l2tp-${MAC}.lastip ]; then
  LASTIP="$(cat /tmp/l2tp-${MAC}.lastip)"
fi

if [ "$LASTIP" != "$RIP" ]; then
  if [ -e /tmp/l2tp-${MAC}.down ]; then
    logger "sudo /tmp/l2tp-${MAC}.down"
    sudo /tmp/l2tp-${MAC}.down
  fi 

  cat <<eof >/tmp/l2tp-${MAC}.up
#!/bin/bash
RPORT=\$RPORT
timeout 5.0s tcpdump -n -c 3 -i $LIF host $RIP and port $PORT 2>/dev/null >/tmp/l2tp-${MAC}.dump
chown www-data:www-data /tmp/l2tp-${MAC}.dump
REALRPORT="\$(awk </tmp/l2tp-${MAC}.dump '/IP/ {split(\$3, x, "."); port=x[5];} END{print port;}')"
if [ ! -z \$REALRPORT ]; then
 RPORT=\$REALRPORT
fi
ip l2tp add tunnel tunnel_id $SID peer_tunnel_id $SID encap udp udp_sport $PORT udp_dport \$RPORT local $LIP remote $RIP || true
ip l2tp add session name E${MAC} tunnel_id $SID session_id $SID peer_session_id $SID  || true
ip link set E${MAC} multicast on || true
# 1392 seems to be OK for at least v4-v4 tunnels through DS-Lite (1460 MTU) AND is divisible by 2, 4, 8.
ip link set E${MAC} mtu 1392 || true
ip link set E${MAC} up || true
brctl addif br-l2tp E${MAC}  || true
eof
  chmod +x /tmp/l2tp-${MAC}.up
  cat <<eof >/tmp/l2tp-${MAC}.down
#!/bin/bash
brctl delif br-l2tp E${MAC}  || true
ip l2tp del session name E${MAC} tunnel_id $SID session_id $SID || true
ip l2tp del tunnel tunnel_id $SID peer_tunnel_id $SID || true
eof
  chmod +x /tmp/l2tp-${MAC}.down

  logger "sudo /tmp/l2tp-${MAC}.up"
  sudo /tmp/l2tp-${MAC}.up
fi

echo "$RIP" >/tmp/l2tp-${MAC}.lastip
echo "OK $SID $PORT $LIP $RIP $BRIP6"
exit 0
