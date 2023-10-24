#!/usr/bin/env bash
container_id="$1" # passwd para desencriptar link_args.aes256

#######################################################################
#  creado por panchuz                                                 
#  para automatizar la creación de un lxc container con zerotier   
#  desde la consola de Proxmox VE  
#######################################################################

# testing configuration for peludo
template_storage=cola
container_storage=cola

# verificación de la cantidad de argumentos
if [ $# -ne 1 ]; then
    echo "Uso: ${BASH_SOURCE[0]} container_id"
    return 1
fi

# carga de biblioteca de funciones generales
#source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)


pct create $contairner_id $template_storage:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz \
	--ostype debian \
	--tags deb12 zerotier \
	--password pancho00 \
	--protction 1 \
	--hostname zerotier \
	--description "Zerotier with NAT-Masq access to phisical net" \
	--cores 1 \
	--memory 512 \
	--swap 512 \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--storage $container_storage \
	--rootfs volume=$container_storage,mountoptions=nodatacow;autodefrag;noatime;lazytime,size=2 \
	--unprivileged 1 \
	--timezone host \
	--onboot 1 #\
	#--hookscript <string> Script that will be exectued during various steps in the containers lifetime.
	#|| return 1

	# the two following lines must be written to .conf file directly
	# pct commnad cannot handle them
	cat <<-EOF >>/etc/pve/lxc/$container_id.conf
		lxc.cgroup2.devices.allow: c 10:200 rwm
		lxc.mount.entry: /dev/net dev/net none bind,create=dir
	EOF

chown 100000:100000 /dev/net/tun
