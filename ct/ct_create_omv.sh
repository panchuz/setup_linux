sh#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]} ct_id"; }

set -u

vars_path="/root/.vars"
ct_create_vars_file="$vars_path"/ct_create.vars.sh
setup_linux_vars_file="$vars_path"/setup_linux.vars.sh
#setup_omv_vars_file="$vars_path"/setup_omv.vars.sh

#######################################################################
#  by panchuz                                                 
#  creation of OMV7 lxc privileged container WITH "lxc.cap.drop:"
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
	--hostname omv \
	--description "OMV7" \
	--tags deb12,util \
	--memory 4096 \
	--swap 1024 \
	--cores 2 \
 	--rootfs "$ct_rootfsstorage":$ct_rootfssize,size=$ct_rootfssize,mountoptions="lazytime;noatime" \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--onboot 1 \
	--arch "$ct_architecture" \
	--protection 0 \
	--unprivileged 0 \
 	--features nesting=1 \
	--timezone host \
 	--start 0 \
	--dev0 $ct_omv_dev_passthrough
	#--hookscript <string> Script that will be exectued during various steps in the containers lifetime.
 	# https://forum.proxmox.com/threads/how-to-use-new-hookscript-feature.53388/post-460707
	#--ssh-public-keys /root/.ssh/authorized_keys \
	#--password "$ct_rootpasswd" \
 
# Voluem identifier format example: pozo:99170/subvol-99170-disk-0.subvol
ct_rootfsvolumeid=$(pct config "$ct_id"|grep -oP 'rootfs: \K[^,]*')

# BTRFS Filesystem in LXC/LXD Container
# "plain" drives (just subvolumes, no raw file) need this to work
# https://forum.proxmox.com/threads/btrfs-filesystem-in-lxc-lxd-container.118803/post-515531
chmod +rx $(pvesm path "$ct_rootfsvolumeid")


# the following line must be written to .conf file directly
# pct commnad cannot handle it
# it lets OMV7 read SMART data from passthroughed devices
echo "lxc.cap.drop =" >>/etc/pve/lxc/$ct_id.conf

pct start "$ct_id" || return 1

# https://gist.github.com/tinoji/7e066d61a84d98374b08d2414d9524f2
pct exec "$ct_id" -- bash -c \
	"usermod --password '$ct_encrootpasswd' root"

# Moving Linux vars file
pct exec "$ct_id" -- bash -c "mkdir $vars_path"
pct push "$ct_id" "$setup_linux_vars_file" "$setup_linux_vars_file"
# following is needed to source "general.func.sh" form within the scripts executed inside ct/vm
pct exec "$ct_id" -- bash -c \
	"echo $'\n\n'export GITHUB_BRANCH=$GITHUB_BRANCH >> $setup_linux_vars_file"

# Linux general setup for the newborn
pct exec "$ct_id" -- bash -c \
	"wget -qP /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_linux.sh &&\
	source /root/setup_linux.sh"

# OMV7 setup
#pct push "$ct_id" "$setup_omv_vars_file" "$setup_omv_vars_file"

pct exec "$ct_id" -- bash -c \
	"wget -qP /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_omv.sh &&\
	source /root/setup_omv.sh"