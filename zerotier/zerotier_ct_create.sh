#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]} ct_id"; }

github_branch=test

vars_path="/root/.vars"
ct_create_vars_file="$vars_path"/ct_create.vars.sh
linux_setup_vars_file="$vars_path"/linux_setup.vars.sh

#######################################################################
#  by panchuz                                                 
#  creation of zerotier lxc container
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 1 ]; then { usage; return 1; }; fi

# Arguments to variables
ct_id="$1" # new container´s ID

# Loads variables in file
source "$ct_create_vars_file" ||return 1

# https://forum.proxmox.com/threads/how-to-create-a-container-from-command-line-pct-create.107304/
# pct create 117 /mnt/pve/cephfs/template/cache/jammy-minimal-cloudimg-amd64-root.tar.xz --hostname gal1 --memory 1024 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.10.1,ip=192.168.10.71/24,tag=10,type=veth --storage localb
# lock --rootfs localblock:8 --unprivileged 1 --pool Containers --ignore-unpack-errors --ssh-public-keys /root/.ssh/authorized_keys --ostype ubuntu --password="$ROOTPASS" --start 1
# abuot rootfs https://forum.proxmox.com/threads/does-proxmox-support-lxc-dir-backend.98486/post-425822
pct create "$ct_id" "$ct_template" \
	--hostname zerotier \
	--description "Zerotier with NAT-Masq access to phisical net" \
	--tags deb12,zerotier \
	--memory 512 \
	--swap 512 \
	--cores 1 \
 	--rootfs "$ct_rootfsstorage":$ct_rootfssize,size=$ct_rootfssize,mountoptions="lazytime;noatime" \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--onboot 1 \
	--arch "$ct_architecture" \
	--protection 1 \
	--unprivileged 1 \
 	--features nesting=1 \
	--timezone host \
 	--start 0 \
 	|| return 1
	#--hookscript <string> Script that will be exectued during various steps in the containers lifetime.
 	# https://forum.proxmox.com/threads/how-to-use-new-hookscript-feature.53388/post-460707
	#--ssh-public-keys /root/.ssh/authorized_keys \
	#--password "$ct_rootpasswd" \
 
# Voluem identifier format example: pozo:99170/subvol-99170-disk-0.subvol
ct_rootfsvolumeid=$(pct config "$ct_id"|grep -oP 'rootfs: \K[^,]*')

# BTRFS Filesystem in LXC/LXD Container
# https://forum.proxmox.com/threads/btrfs-filesystem-in-lxc-lxd-container.118803/post-515531
chmod +rx $(pvesm path "$ct_rootfsvolumeid")


# the two following lines must be written to .conf file directly
# pct commnad cannot handle them
cat <<-EOF >>/etc/pve/lxc/$ct_id.conf
	lxc.cgroup2.devices.allow: c 10:200 rwm
	lxc.mount.entry: /dev/net dev/net none bind,create=dir
EOF

chown 100000:100000 /dev/net/tun

pct start "$ct_id" || return 1

# https://gist.github.com/tinoji/7e066d61a84d98374b08d2414d9524f2
pct exec "$ct_id" -- bash -c \
	"usermod --password '$ct_encrootpasswd' root"

# Moving vars file
pct exec "$ct_id" -- bash -c \
	"mkdir $vars_path"
pct push "$ct_id" "$linux_setup_vars_file" "$linux_setup_vars_file"

pct exec "$ct_id" -- bash -c \
	"wget -qP /root https://github.com/panchuz/linux_setup/raw/$github_branch/linux_setup.sh &&\
	source /root/linux_setup.sh"

#
