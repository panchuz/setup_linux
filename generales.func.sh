# FUNCIONES GENERALES para bash scripts

# Determinación robusta* del directorio de este script para que conste en el encabezado
# *a prueba de source y simlinks de directorio y archivo
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
script_directorio_nombre_stdout () {
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


# --- ENCRIPTA con openssl ---
# retorna 0/1 si éxito/fracaso
encript_stdout () {
	# $1: cosa a encriptar
	# $2: password
	if [ $# -eq 2 ]; then
		echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:"$2";
	else
		return 1
	fi
}


# --- GENERA Y GUARDA link_args.aes256 ---
genera_link_args_aes256 () {
	# $1: password
	encript_stdout "${_LINK_ARGS}" "$1" > link_args.aes256
}



# --- DESENCRIPTA con openssl ---
# retorna 0/1 si éxito/fracaso: return OK
desencript_stdout () {
	# $1: cosa encriptada
	# $2: password
	echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:"$2"
}


# apt-get update and upgrade automate and unattended
# https://www.cyberciti.biz/faq/explain-debian_frontend-apt-get-variable-for-ubuntu-debian/
# https://devicetests.com/silence-apt-get-install-output
# https://peteris.rocks/blog/quiet-and-unattended-installation-with-apt-get/
debian_dist-upgrade_install () {
	## argumentos: paquetes a instalar luego del dist-upgrade
	# se comentó la sig línea para evitar el reinicio automático
	#export NEEDRESTART_MODE=a
	export DEBIAN_FRONTEND=noninteractive
	# Questions that you really, really need to see (or else). ##
	export DEBIAN_PRIORITY=critical
	apt-get -qq update
	#apt-get -qq -o "Dpkg::Options::=--force-confnew" -o=Dpkg::Use-Pty=0 dist-upgrade
	#apt-get -o=Dpkg::Use-Pty=0 no parece funcionar, genera output igual
	printf "ejecutando apt-get upgrade... "
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
		upgrade >/dev/null && printf "Éxito\n"
	printf "ejecutando apt-get dist-upgrade... "
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
		dist-upgrade >/dev/null && printf "Éxito\n"
	if [ $# -gt 0 ]; then
 		printf "ejecutando apt-get install $*... "
   		apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
			install "$@" >/dev/null && printf "Éxito\n"
	fi
 	printf "limpiando... "
	apt-get -qq clean
 	apt-get -qq autoclean
  	apt-get -qq autoremove && printf "Éxito\n"
   	printf "escribiendo a disco... "
	sync && printf "Éxito\n"
}


# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
verif_privilegios_root () {
	if (( $EUID != 0 )); then
		printf "ERROR: Este script se debe ejecutar con privilegios root (printf)\n"
		return 1
  	else
   		return 0
	fi
}


