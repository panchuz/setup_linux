#!/usr/bin/env bash
ct_id="$1" # passwd para desencriptar link_args.aes256

#######################################################################
#  creado por panchuz                                                 
#  para automatizar la creación de un lxc container con zerotier   
#  desde la consola de Proxmox VE  
#######################################################################

# testing configuration for peludo
ct_template="/mnt/cola/@pve-storage/template/cache/debian-12-standard_12.0-1_amd64.tar.zst"
ct_storage=cola
ct_storage_size=2
ct_rootpasswd="pancho00"

# verificación de la cantidad de argumentos
if [ $# -ne 1 ]; then
    echo "Uso: ${BASH_SOURCE[0]} ct_id"
    return 1
fi

# carga de biblioteca de funciones generales
#source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)


pct create $ct_id "$ct_template" \
	--hostname zerotier \
	--description "Zerotier with NAT-Masq access to phisical net" \
	--tags deb12 zerotier \
	--ostype debian \
	--protection 1 \
	--cores 1 \
	--memory 512 \
	--swap 512 \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--storage $ct_storage \
	--rootfs $ct_storage:$ct_storage_size \
	--unprivileged 1 \
	--onboot 1 \
	--password="$ct_rootpasswd" \
	--timezone host || exit 1
	#--rootfs volume=$ct_storage,mountoptions=nodatacow;autodefrag;noatime;lazytime,size=2 \
	#--hookscript <string> Script that will be exectued during various steps in the containers lifetime.

# the two following lines must be written to .conf file directly
# pct commnad cannot handle them
cat <<-EOF >>/etc/pve/lxc/$ct_id.conf
	lxc.cgroup2.devices.allow: c 10:200 rwm
	lxc.mount.entry: /dev/net dev/net none bind,create=dir
EOF

chown 100000:100000 /dev/net/tun
