#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]}\nNo arguments supported"; }

set -eu

# variables file 
#vars_path="/root/.vars"
#setup_omv_vars_file="$vars_path"/setup_omv.vars.sh

#######################################################################
#  by panchuz
#  to install and run OMV7 on debian 12 privileged lxc container
#  it needs "lxc.cap.drop:" in /etc/pve/lxc/*.conf
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 0 ]; then { usage; return 1; }; fi

# --- Loads variables  ---
#source "$setup_omv_vars_file"

# Load general functions 
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/general.func.sh)


#------------------FUNCIÓN main------------------
main () {
	# https://forum.openmediavault.org/index.php?thread/50222-install-omv7-on-debian-12-bookworm/&postID=371929#post371929	# https://pkg.omv.com/index.html#debian-bookworm
	cat <<-EOF >> /etc/apt/sources.list.d/openmediavault.list
		deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public sandworm main
		# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://downloads.sourceforge.net/project/openmediavault/packages sandworm main
		## Uncomment the following line to add software from the proposed repository.
		# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public sandworm-proposed main
		# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://downloads.sourceforge.net/project/openmediavault/packages sandworm-proposed main
		## This software is not part of OpenMediaVault, but is offered by third-party
		## developers as a service to OpenMediaVault users.
		# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public sandworm partner
		# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] http://downloads.sourceforge.net/project/openmediavault/packages sandworm partner
	EOF
	
	export LANG=C.UTF-8
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	apt-get install --yes gnupg
	wget --quiet --output-document=- https://packages.openmediavault.org/public/archive.key | gpg --dearmor --yes --output "/usr/share/keyrings/openmediavault-archive-keyring.gpg"
	apt-get update
	apt-get --yes --auto-remove --show-upgraded --allow-downgrades --allow-change-held-packages --no-install-recommends --option DPkg::Options::="--force-confdef" --option DPkg::Options::="--force-confold" install openmediavault-keyring openmediavault

	# Populate the database.
	omv-confdbadm populate

	# Display the login information.
	omv-salt deploy run hosts
	cat /etc/issue

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
