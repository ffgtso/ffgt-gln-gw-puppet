#!/usr/bin/env bash
#
# Build for interactive use, i. e. set PATH accordingly if run via micron.d
#
# To facilitate "virtual remote execution" ;), enter target hostname as $1
#
# Basic idea is to automate creation of script input; for dynamic routing
# one needs more or less a full mesh of connections between a whole lot of
# nodes, if I have e. g. two times two external peers and four rouing nodes,
# a total of 2x4 + 2x4 + (4 x (4-1))/2, i. e. 8+8+6 links == tunnels would
# be needed. Automating creating the input.yaml file semms logical ...

uname="`uname -n`"
if [ $# -eq 1 ]; then
  uname="$1"
  (>&2 echo "Using $1 as local hostname")
fi

if [ ! -e  tunnel-def.txt ]; then
  (>&2 echo "Error: You need a ./tunnel-def.txt file. See $0 for details.")
  exit 1
fi

SEDFILE="tunnel-mapping.sed"
if [ ! -e "${SEDFILE}" ]; then
  SEDFILE=/dev/null
fi

# Make sure we don't get surprised by I8N ;-)
LANG=C
export LANG

# To map host names to the bgp/gw/xx/s schema, create a sed input
# file ./tunnel-mapping.sed, otherwise /dev/null is used.
#
# Format of tunnel-def.txt is link-spec <space> tunnel-type, e. g.
#
# bgp1-gw01 gre
# gw01-s3 l2tp
# bgp1-bgp2 l2tp

for i in `sed -e 's/ /;/g' <tunnel-mapping.txt | grep ${uname}`
do
  linkspec="`echo $i | cut -d ";" -f 1`"
  TYPE="`echo $i | cut -d ";" -f 2`"
  LHS="`echo ${linkspec} | awk '{split($1, lp, "-"); print lp[1];}'`"
  RHS="`echo ${linkspec} | awk '{split($1, lp, "-"); print lp[2];}'`"
  LHTMPNAME="`echo ${linkspec} | cut -d " " -f 1 | sed -f ${SEDFILE} | awk '{split($1, lp, "-"); print lp[1];}'`"
  RHTMPNAME="`echo ${linkspec} | cut -d " " -f 1 | sed -f ${SEDFILE} | awk '{split($1, lp, "-"); print lp[2];}'`"
  domain="4830.org"
  tunprefix="ffgt"
  LHSIP="`host ${LHS}.${domain} | awk '/has address/ {print $NF;}'`"
  RHSIP="`host ${RHS}.${domain} | awk '/has address/ {print $NF;}'`"
  if [ "$LHS" = "$uname" ]; then
    echo "${tunprefix}-${RHS}:"
    echo "  pub4src: \"$LHSIP\""
    echo "  pub4dst: \"$RHSIP\""
    /usr/local/bin/tun-ip.sh $LHTMPNAME-$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    /usr/local/bin/tun-ip.sh $RHTMPNAME-$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    echo "  mode: \"${TYPE}\""
  else
    echo "${tunprefix}-${LHS}:"
    echo "  pub4src: \"$RHSIP\""
    echo "  pub4dst: \"$LHSIP\""
    /usr/local/bin/tun-ip.sh $LHTMPNAME-$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    /usr/local/bin/tun-ip.sh $RHTMPNAME-$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    echo "  mode: \"${TYPE}\""
  fi
  echo
done | sed -e 's%/64%%g'> tunnel.yaml
