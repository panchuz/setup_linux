#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]}\nNo arguments supported"; }

# variables file 
vars_path="/root/.vars"
zerotier_setup_vars_file="$vars_path"/zerotier_setup.vars.sh

#######################################################################
#  by panchuz
#  to install and configure zerotier to connecto to a netowork
#  and route to fisical network
#  https://zerotier.atlassian.net/wiki/x/CgBgDQ  
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 0 ]; then { usage; return 1; }; fi

# --- Loads variables  ---
source "$zerotier_setup_vars_file" || return 1

# Load general functions 
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_setup/main/general.func.sh)

	 
# CREA DROP-IN PARA ACCESO A LAN FÍSICA DESDE ZEROTIER
crea_dropin_zerotier () {
	cat >/etc/systemd/system/zerotier-one.service.d/nat-masq"$MARK".conf <<-EOF
		$encabezado
		#
		# Unit file original en /usr/lib/systemd/system/zerotier-one.service
		# Este drop-in debe ubicarse en /etc/systemd/system/zerotier-one.service.d/nat-masq_panchuz.conf
		# https://wiki.archlinux.org/title/systemd#Drop-in_files

		[Unit]
		Description=ZeroTier One + drop-in para acceder a LAN fisica

		[Service]
		# https://zerotier.atlassian.net/wiki/spaces/SD/pages/224395274/Route+between+ZeroTier+and+Physical+Networks
		# https://wiki.nftables.org/wiki-nftables/index.php/Performing_Network_Address_Translation_(NAT)#Masquerading
		# https://wiki.archlinux.org/title/nftables

		ExecStartPost= /usr/sbin/sysctl -w net.ipv4.ip_forward=1
		# Se reescribe la siguiente línea por su extesión
		#ExecStartPost= /usr/sbin/nft add table ip zt-nat { chain post { type nat hook postrouting priority srcnat \; oifname "eth0" masquerade \;  } \; }
		ExecStartPost= /usr/sbin/nft add table ip zt-nat-masq { \\
		        chain post { \\
		            type nat hook postrouting priority srcnat \; \\
		            oifname "eth0" masquerade \; \\
		        } \; \\
		    }

		ExecStopPost= /usr/sbin/nft delete table ip zt-nat-masq
		ExecStopPost= /usr/sbin/sysctl -w net.ipv4.ip_forward=0
	EOF
}


#------------------FUNCIÓN main------------------
main () {
	debian_dist_upgrade_install zerotier-one ||return 1

	zerotier-cli join $NETWORK_ID
	zerotier-cli listnetworks

	echo "Authorize $(hostname) at my.zerotier.com/network/$NETWORK_ID"

	# genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado
	encabezado="$(encabezado_stdout)"

	crea_dropin_zerotier

	systemctl daemon-reload
	systemctl restart zerotier-one.service
	
 	# reboot needed ???
 	if [ -f /var/run/reboot-required ]; then
  		echo "--- REBOOT REQUIERD ---"
	#	/bin/sleep 5
	#	reboot
 	else
 		echo "Reboot NOT requierd"
  	fi
}


# Root privileges verification
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( EUID == 0 )); then
	main
else
	echo "ERROR: Must be run with root privileges"
fi
