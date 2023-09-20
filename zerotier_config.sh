#!/usr/bin/env bash
#passwd_link_args_aes256="$1" # passwd para desencriptar link_args.aes256

#######################################################################
#  creado por panchuz                                                 
#  para automatizar la configuración inicial de lxc con zerotier en base  
#  al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE  
#######################################################################

# verificación de la cantidad de argumentos
#if [ $# -ne 1 ]; then
#    echo "Uso: ${BASH_SOURCE[0]} passwd_link_args_aes256"
#    return 1
#fi

# carga de biblioteca de funciones generales
#source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	cat <<-EOF
		# creado por (BASH_SOURCE):	${BASH_SOURCE[0]}
		# fecha y hora:	$(date +%F_%T_TZ:%Z)
		# nombre host:	$(hostname)
		# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
		#
		
	EOF
}
	 
# CREA DROP-IN PARA ACCESO A LAN FÍSICA DESDE ZEROTIER
crear_dropin_zerotier () {
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
