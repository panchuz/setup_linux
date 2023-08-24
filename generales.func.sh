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
# https://devicetests.com/silence-apt-get-install-output
# https://peteris.rocks/blog/quiet-and-unattended-installation-with-apt-get/
function debian_dist-upgrade () {
	# sin rebooteo automático:
	# export NEEDRESTART_MODE=a
	export DEBIAN_FRONTEND=noninteractive
	## Questions that you really, really need to see (or else). ##
	export DEBIAN_PRIORITY=critical
	apt-get -qq update
	#apt-get -qq -o "Dpkg::Options::=--force-confnew" -o=Dpkg::Use-Pty=0 dist-upgrade
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade > /dev/null
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" dist-upgrade > /dev/null
 	apt-get -qq clean
 	apt-get -qq autoclean
  	apt-get -qq autoremove
   	sync
}


# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
function verif_privilegios_root () {
	if (( $EUID != 0 )); then
		printf "ERROR: Este script se debe ejecutar con privilegios root (printf)\n"
		return 1
  	else
   		return 0
	fi
}


