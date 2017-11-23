#!/bin/bash
if [ $# -ne 2 ]; then
  logger "$0: ERROR: Too few arguments ($#)"
  echo "NAK"
  exit 0
fi

MAC="$1"
RIP="$2"
#LIP="$(ip -o -4 addr show dev ens3 | awk '{printf("%s", substr($4, 1, index($4, "/")-1));}')"
LIP="192.251.226.19"
PORT=10000
SID="$(echo $MAC | awk -Wposix '{printf("%d", "0x" substr($1, 9,4));}')"

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
ip l2tp add tunnel tunnel_id $SID peer_tunnel_id $SID encap udp udp_sport $PORT udp_dport $PORT local $LIP remote $RIP || true
ip l2tp add session name E${MAC} tunnel_id $SID session_id $SID peer_session_id $SID  || true
ip link set E${MAC} multicast on || true
ip link set E${MAC} mtu 1500 || true
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

echo "OK $SID $PORT $LIP $RIP"
exit 0
