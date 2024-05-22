#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]}\nNo arguments supported"; }

set -e -u

# variables file 
vars_path="/root/.vars"
setup_vars_file="$vars_path"/setup_cloudflare.vars.sh

#######################################################################
#  by panchuz
#  to install and run cloudflared connector
#
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 0 ]; then { usage; return 1; }; fi

# --- Loads variables  ---
source "$setup_cloudflare_vars_file"

# Load general functions 
# source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$github_branch/general.func.sh)


#------------------FUNCIÓN main------------------
main () {
	debian_dist_upgrade_install curl

	curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
	dpkg -i cloudflared.deb
	cloudflared service install "$cloudflared_token"
	
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
