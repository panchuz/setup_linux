#!/usr/bin/env bash
ct_id="$1" # new container´s ID

#######################################################################
#  creado por panchuz                                                 
#  para automatizar la creación de un lxc container con zerotier   
#  desde la consola de Proxmox VE  
#######################################################################

# testing configuration for peludo
#ct_template="/mnt/cola/@pve-storage/template/cache/debian-12-standard_12.0-1_amd64.tar.zst"
ct_template="cola:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
ct_rootfsstorage=cola
ct_rootfssize=2
ct_rootpasswd="pancho00"
ct_architecture=$(dpkg --print-architecture))


# checking the number of arguments
if [ $# -ne 1 ]; then
    echo "Uso: ${BASH_SOURCE[0]} ct_id"
    return 1
fi

# carga de biblioteca de funciones generales
#source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# https://forum.proxmox.com/threads/how-to-create-a-container-from-command-line-pct-create.107304/
# root@pve1:~# pct create 117 /mnt/pve/cephfs/template/cache/jammy-minimal-cloudimg-amd64-root.tar.xz
# 	--hostname gal1 --memory 1024 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.10.1,ip=192.168.10.71/24,tag=10,type=veth --storage localblock --rootfs volume=localblock:vm-117-disk-0,mountoptions=noatime,size=8G --unprivileged 1 --pool Containers
# unable to create CT 117 - no such logical volume pve/vm-117-disk-0
pct create $ct_id "$ct_template" \
	--hostname zerotier \
	--description "Zerotier with NAT-Masq access to phisical net" \
	--tags deb12,zerotier \
	--password "$ct_rootpasswd" \
	--memory 512 \
	--swap 512 \
	--cores 1 \
	--rootfs $ct_rootfsstorage:$ct_rootfssize,mountoptions="noatime;lazytime" \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--onboot 1 \
	--arch $ct_architecture \
	--protection 1 \
	--unprivileged 1 \
	--timezone host \
	|| exit 1
	#--hookscript <string> Script that will be exectued during various steps in the containers lifetime.

# the two following lines must be written to .conf file directly
# pct commnad cannot handle them
cat <<-EOF >>/etc/pve/lxc/$ct_id.conf
	lxc.cgroup2.devices.allow: c 10:200 rwm
	lxc.mount.entry: /dev/net dev/net none bind,create=dir
EOF

chown 100000:100000 /dev/net/tun
