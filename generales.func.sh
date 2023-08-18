# FUNCIONES GENERALES para bash scripts

# Determinación robusta* del directorio de este script para que conste en el encabezado
# *a prueba de source y simlinks de directorio y archivo
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
function script_directorio_nombre_stdout () {
	local source=${BASH_SOURCE[0]}
	while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
	  local directorio=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
	  source=$(readlink "$source")
	  [[ $source != /* ]] && source=$directorio/$source # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	directorio=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
	local nombre=$(basename "$source")
	printf "${directorio}/${nombre}"
}


# apt-get update and upgrade automate and unattended
# https://www.cyberciti.biz/faq/explain-debian_frontend-apt-get-variable-for-ubuntu-debian/
function nuevo_debian_dist-upgrade () {
	# local NEEDRESTART_MODE=a
	local DEBIAN_FRONTEND=noninteractive
	## Questions that you really, really need to see (or else). ##
	local DEBIAN_PRIORITY=critical
	apt-get -qy update
	apt-get -qy -o "Dpkg::Options::=--force-confnew" dist-upgrade
	apt-get -qy clean
	apt-get -qy autoremove
}


# apt-get update and upgrade automate and unattended
# https://www.cyberciti.biz/faq/explain-debian_frontend-apt-get-variable-for-ubuntu-debian/
function debian_dist-upgrade_reboot () {
	# local NEEDRESTART_MODE=a
	local DEBIAN_FRONTEND=noninteractive
	## Questions that you really, really need to see (or else). ##
	local DEBIAN_PRIORITY=critical
	apt-get -qy update
	apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" dist-upgrade
	apt-get -qy clean
	apt-get -qy autoremove
	if [ -f /var/run/reboot-required ]; then
		reboot
	fi
}

# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
function verif_privilegios_root () {
	if (( $EUID != 0 )); then
		printf "ERROR: Este script se debe ejecutar con privilegios root\n"
		return
	fi
}


