#!/bin/sh
#
#
#    1        2         3       4
#  bgp0-15, gw00-gw15, s0-15, xx00-15
#
#
# Usage: $0 bgp1-gw04

if [ $# -ne 1 ]; then
    echo "Usage: $0 bgp1-gw04"
    exit 1
fi

#echo "$1" | gawk '{n=split($1, nodes, "-"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} printf("%s %s\n", nodes[1], nodes[2]); xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {printf("%s ... ", substr(nodes[i], 1, 1)); switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;} printf("%d\n", xval[i]);} x=sprintf("%1d%1d", xval[1], xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} printf("%s (%d) %s (%d)\n", nodes[1], nodes[1], nodes[2], nodes[2]); y=nodes[1]*16+nodes[2]; printf("%s => %d.%d (0x%x.0x%x)\n", $1, x, y, x, y);}'

echo "$1" | gawk '{n=split($1, nodes, "-"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;}} x=sprintf("%1d%1d", xval[1], xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} y=nodes[1]*16+nodes[2]; printf("IPv4: 10.234.%d.%d\n", x, y);}'

#echo "$1" | gawk '{n=split($1, nodes, "-"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} printf("%s %s\n", nodes[1], nodes[2]); xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {printf("%s ... ", substr(nodes[i], 1, 1)); switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;}  printf("%d\n", xval[i]);} if(xval[2]<xval[1]) {tmp=xval[1]; xval[1]=xval[2]; xval[2]=tmp; localip=1;} else {localip=2;} xval[1]--; xval[2]--; x=sprintf("%d", xval[1]*4+xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} printf("%s (%d) %s (%d)\n", nodes[1], nodes[1], nodes[2], nodes[2]); y=nodes[1]*16+nodes[2]; printf("%s => xxxx:xxxx:xxxx:0%1x%02x::%d/64\n", $1, x, y, localip);}'

echo "$1" | gawk '{n=split($1, nodes, "-"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;}} if(xval[2]<xval[1]) {tmp=xval[1]; xval[1]=xval[2]; xval[2]=tmp; localip=1;} else {localip=2;} xval[1]--; xval[2]--; x=sprintf("%d", xval[1]*4+xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} if(xval[2]==xval[1]) {if(nodes[2]<nodes[1]) {tmp=nodes[1]; nodes[1]=nodes[2]; nodes[2]=tmp; localip=1;} else {localip=2;}} else if(localip==1) {tmp=nodes[1]; nodes[1]=nodes[2]; nodes[2]=tmp;} y=nodes[1]*16+nodes[2]; printf("IPv6: 2a03:2260:117:0%1x%02x::%d/64\n", x, y, localip);}'
