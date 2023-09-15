#!/usr/bin/env bash
# FUNCIONES GENERALES para bash scripts

# Determinación robusta* del directorio de este script para que conste en el encabezado
# *a prueba de source y simlinks de directorio y archivo
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
script_directorio_nombre_stdout () {
	local source
	source=${BASH_SOURCE[0]}
	local directorio
	while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
	  directorio=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
	  source=$(readlink "$source")
	  [[ $source != /* ]] && source=$directorio/$source # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	directorio=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
	local nombre
	nombre=$(basename "$source")
	echo "$directorio/$nombre"
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
	echo "ejecutando apt-get upgrade... "
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
		upgrade >/dev/null && echo "Éxito"
	echo "ejecutando apt-get dist-upgrade... "
	apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
		dist-upgrade >/dev/null && echo "Éxito"
	if [ $# -gt 0 ]; then
 		echo "ejecutando apt-get install $*... "
   		apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" \
			install "$@" >/dev/null && echo "Éxito"
	fi
 	echo "limpiando... "
	apt-get -qq clean
 	apt-get -qq autoclean
  	apt-get -qq autoremove && echo "Éxito"
   	echo "escribiendo a disco... "
	sync && echo "Éxito"
}


# --- AGREGADO Y CONFIGURACIÓN NUEVO_USUARIO como admin ---
agregar_usuario_admin () {
	nuevo_usuario="$1"
	id_nuevo_usuario="$2"
	passwd_nuevo_usuario="$3"
	ssh_pub_key_nuevo_usuario="$4"

	useradd --uid "$id_nuevo_usuario "\
		--shell /bin/bash \
		--create-home \
		--groups sudo,systemd-journal,adm \
		"$nuevo_usuario" \
		|| return 1

	echo "$nuevo_usuario:$passwd_nuevo_usuario" | chpasswd

	# Para poder hacer ping http://unixetc.co.uk/2016/05/30/linux-capabilities-and-ping/
	setcap cap_net_raw+p "$(which ping)"

	# crea el archivo de la clave ssh pública del usuario
	local nuevo_usuario_sshkey_dir
	nuevo_usuario_sshkey_dir="$(eval echo "~$nuevo_usuario")/.ssh"
	mkdir "$nuevo_usuario_sshkey_dir"
	cat >"$nuevo_usuario_sshkey_dir"/authorized_keys"$MARCA" <<-EOF
		encabezado
		# http://man.he.net/man5/authorized_keys
		#
		$ssh_pub_key_nuevo_usuario
	EOF
	chown --recursive "$nuevo_usuario:$nuevo_usuario" "$nuevo_usuario_sshkey_dir"
	chmod 600 "$nuevo_usuario_sshkey_dir"/*
}



# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
verif_privilegios_root () {
	if (( EUID != 0 )); then
		echo "ERROR: Este script se debe ejecutar con privilegios root (echo)"
		return 1
  	else
   		return 0
	fi
}


