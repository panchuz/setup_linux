#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]} ct_id ct_hostname ct_description"; }

set -u

vars_path="/root/.vars"
ct_create_vars_file="$vars_path"/ct_create.vars.sh
setup_linux_vars_file="$vars_path"/setup_linux.vars.sh

#######################################################################
#  by panchuz                                                 
#  creation of lxc container
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 3 ]; then { usage; return 1; }; fi

# Arguments to variables
ct_id="$1" # new container´s ID
ct_hostname="$2"  # new container´s hostname
ct_description="$3" # new container´s description

# Loads variables in file
source "$ct_create_vars_file" ||return 1

# https://forum.proxmox.com/threads/how-to-create-a-container-from-command-line-pct-create.107304/
# about rootfs https://forum.proxmox.com/threads/does-proxmox-support-lxc-dir-backend.98486/post-425822
pct create "$ct_id" "$ct_template" \
	--hostname "$ct_hostname" \
	--description "$ct_description" \
	--tags deb12 \
	--memory 512 \
	--swap 512 \
	--cores 1 \
 	--rootfs "$ct_rootfsstorage":$ct_rootfssize,size=$ct_rootfssize,mountoptions="lazytime;noatime" \
	--net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--onboot 0 \
	--arch "$ct_architecture" \
	--protection 0 \
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
# "plain" drives (just subvolumes, no raw file) need this to work
# https://forum.proxmox.com/threads/btrfs-filesystem-in-lxc-lxd-container.118803/post-515531
chmod +rx $(pvesm path "$ct_rootfsvolumeid")


#
# something that MUST be done before starting the ct???
#

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
