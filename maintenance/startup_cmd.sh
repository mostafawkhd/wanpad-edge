#!/bin/bash
set -euxo pipefail
# git pull
. .env
#number of arguments
NA=`echo $* | wc -w `
OLD_HOSTNAME=`hostname`
install_deps () {
	apt install `cat apt_dependencies | xargs`
}
usage () {
	echo "usage :
	./startup_cmd.sh new_hostname [static_ip] [gateway] [dns servers]
		
		new_hostname: without spaces
		
		static_ip: set an ip address if you want to set static ip for eno1
			NOTE: static_ip must be defined in CIDR format

		gateway: if not specified, sets to the first three octals of static_ip + \".1\"

		dns-servers: in comma seperated format
			e.g: 1.1.1.1,9.9.9.9
		if you also like to restore the default key set restore_key=true in .env
	"
}
# check_ip_cidr () {
# 	echo $IP
# 	is_cidr=`echo $IP ; cut -d '/' -f2`
# 	echo salam
# 	if [[ -z $is_cidr ]]
# 	then
# 		echo salma
# 		 usage
# 		 exit 1
# 	fi
# }

restore_key () {

if [[ $restore_key == true  ]]
then
 ./restore_authorized_keys.sh 
fi
}



change_dsf () {
	rm /etc/ssh/ssh_host_*  || true
	dpkg-reconfigure -p critical openssh-server 
}


function calculate_gw {
	GW=${IP%.*}.1
	echo You did not specify Gateway in the inputs, using $GW as gateway
}
function set_default_dns {
	DNS=$DEFAULT_DNS
	echo You did not specify DNS server\(s\) in the inputs, using $DNS as DNS server
}
function no_ch_ip {
	echo You did not specify an IP address. keeping the current network configurations.
	exit 0
}

function ch_hostname {
	hostname $NEW_HOSTNAME
	sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
	sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
}
function verify_ch_hostname {
	local tmp=`hostname`
	if [[ $tmp  == $NEW_HOSTNAME ]]
	then
		echo hostname is successfully updated. prompt will be fixed with a new login.
	else
		echo new hostname is not the same as you wished to be 
	fi	
}
function configure_network {
	sed "s|\${IP}|$IP|g" ./base_netplan.yaml > /tmp/00-installer-config.yaml
	sed -i "s|\${GW}|$GW|g" /tmp/00-installer-config.yaml
	sed -i "s|\${DNS}|$DNS|g" /tmp/00-installer-config.yaml
	sed -i "s|\${INTERFACE_NAME}|$INTERFACE_NAME|g" /tmp/00-installer-config.yaml
	cat /tmp/00-installer-config.yaml > /etc/netplan/00-installer-config.yaml
	netplan apply 
}
 restore_key

case	"$NA" in
4)
 NEW_HOSTNAME=$1
 IP=$2
 # check_ip_cidr
 GW=$3
 DNS=$4
 change_dsf
 ch_hostname
 configure_network
install_deps
 ;;
3)
 NEW_HOSTNAME=$1
 IP=$2
 # check_ip_cidr
 GW=$3
 change_dsf
 ch_hostname
 set_default_dns
 configure_network
install_deps
 ;;
2)
 NEW_HOSTNAME=$1
 IP=$2
 # check_ip_cidr
 change_dsf
 ch_hostname
 calculate_gw
 set_default_dns
 configure_network
install_deps
 ;;
1)
 NEW_HOSTNAME=$1
 change_dsf
 ch_hostname
 verify_ch_hostname
 no_ch_ip
install_deps
 ;;
*)
 usage
 ;;
esac
