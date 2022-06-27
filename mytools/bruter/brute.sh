#!/bin/bash

MYHASH="$1"
SALT="${2:-25c5850100451f12}"
WORDLIST="${3:-/usr/share/wordlists/rockyou.txt}"
PHPFILE=$(mktemp) #"decrypt.php"

lines=$(wc -l "$WORDLIST" | cut -d ' ' -f1)

echo "Usage: <hash> <salt> <wordlist>"
echo
echo "Cracking hash : $MYHASH w/ salt : $SALT"
echo "Number of passwords : $lines"
echo

generate() {
 echo -n '<?php
  function hashpass($password) {
    $algo = "\$6";               # sha512
    $cost = "\$rounds=25000\$";   # Cost parameter, 25k iterations
    $salt = "'$SALT'"; # salt

    $full_hash = crypt($password, $algo.$cost.$salt);   
    $full_salt = substr($full_hash, 0, 33);                                                                                                                                                                                                   
    $hashed_password = substr($full_hash, 33);

    return $hashed_password;
  }

  $password = trim(fgets(STDIN));
  echo hashpass($password);
?>' > "$PHPFILE"
}

check() {
  hash=$(echo $1 | php -f "$PHPFILE")
  if [ "$hash" = "$MYHASH" ]; then
    return 0
  fi

  return 1
}

BAR=$(perl -e 'print "#"x100')

index=0

generate

cat "$WORDLIST" | while read pass
do
  let "index++"
  let "percent=100*index/lines"

  printf "%-80s" "$pass"
  echo -ne "\r%$percent ${BAR:0:$percent}  "

  #if [ ${#pass} -gt 40 ]; then
  #  continue
  #fi

  check $pass
  if [ $? -eq 0 ]; then
    echo -ne "\rFOUND = $pass"
    break
  fi
done
