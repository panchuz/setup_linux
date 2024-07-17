#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]}\nNo arguments supported"; }

set -u

# variables file 
vars_path="/root/.vars"
setup_cloudflare_vars_file="$vars_path"/setup_cloudflare.vars.sh

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
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/general.func.sh)


#------------------FUNCIÓN main------------------
main () {
	# https://pkg.cloudflare.com/index.html#debian-bookworm
	# Add cloudflare gpg key
	#_NOT NEEDED: mkdir -p --mode=0755 /usr/share/keyrings
	curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

	# Add this repo to your apt repositories
	echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main' | tee /etc/apt/sources.list.d/cloudflared.list

	# install cloudflared
	apt-get install cloudflared

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
