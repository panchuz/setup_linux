#!/usr/bin/env bash
passwd_link_args_aes256="$1" # passwd para desencriptar link_args.aes256

#######################################################################
#  creado por panchuz                                                 
#  para automatizar la configuración inicial de lxc con zerotier en base  
#  al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE  
#######################################################################

# verificación de la cantidad de argumentos
if [ $# -ne 1 ]; then
    echo "Uso: ${BASH_SOURCE[0]} passwd_link_args_aes256"
    return 1
fi

# carga de biblioteca de funciones generales
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

	 
# CREA DROP-IN PARA ACCESO A LAN FÍSICA DESDE ZEROTIER
crea_dropin_zerotier () {
	cat >/etc/systemd/system/zerotier-one.service.d/nat-masq"$MARCA".conf <<-EOF
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

		ExecStopPost= /usr/sbin/nft delete table ip zt-nat
		ExecStopPost= /usr/sbin/sysctl -w net.ipv4.ip_forward=0
	EOF
}


#------------------FUNCIÓN main------------------
main () {
	passwd_link_args_aes256="$1"

	#carga de argumentos
	wget --quiet https://github.com/panchuz/linux_config_inicial/raw/main/link_args.aes256
	link_args=$(desencript_stdout "$(cat link_args.aes256)" "$passwd_link_args_aes256")
	source <(wget --quiet -O - --no-check-certificate "$link_args")

	debian_dist-upgrade_install zerotier-one

	# genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado
	encabezado="$(encabezado_stdout)"

	crea_dropin_zerotier

 	# reboot necesario????
 	if [ -f /var/run/reboot-required ]; then
  		echo "Se procede a reiniciar"
		/bin/sleep 5
		reboot
 	else
 		echo "NO se necesita reiniciar"
  	fi
}


# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( EUID == 0 )); then
	main "$passwd_link_args_aes256"
else
	echo "ERROR: Este script se debe ejecutar con privilegios root"
fi
