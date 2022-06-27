#!/usr/bin/env python3

import os
import hashlib
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('input')
parser.add_argument('-t',dest='type', choices=['md5','sha256'], default='md5')
parser.add_argument('-d',dest='directory', default='/usr/share/seclists/Passwords')

args = parser.parse_args()

keyword = args.input
type = args.type # "c39436ee452e641cde2eb992ab397911"
directory = args.directory 

if type == "md5":
    func = hashlib.md5
elif type == "sha256":
    func = hashlib.sha256
else:
    print(f"unknown type: {type}" )
    exit(-1)

def encrypt(password):
    h = func(password)
    return h.hexdigest()

print('type = ' + type)

found = False

for entry in os.scandir(directory):
    if found:
        break

    if entry.is_dir():
        continue

    ap = os.path.join(directory, entry.name)

    print(f"[!] Testing password file : {ap}")

    with open(ap, "r", errors='ignore') as f:
        for line in f:
            password = line.strip()

            digest = encrypt(password.encode())

            if keyword == digest:
                found = True
                print(f"[+] Password found : {password}")
                break

if not found:
    print("[-] No cleartext password found")
