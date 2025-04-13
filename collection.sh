#/bin/sh

echo -e "Executing Collection via Automated Collection script. Trying to dump information from etc/passwd"
sh -c "/bin/grep 'x:0:' /etc/passwd > /tmp/passwords"

#this script is for demo purposes only