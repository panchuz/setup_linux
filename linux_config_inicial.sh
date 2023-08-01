#!/usr/bin/env bash
#{reemplazado}!/bin/bash
# source <(wget -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# creado por panchuz
# para automatizar la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE

# Opciones para la configuración
export LANG=C.utf8 # quedará de forma permamente. Ver: function crear_archivo_profile_local ()
HUSO_HORARIO=America/Argentina/Buenos_Aires

# el contenido de la sig variable sirve para appendear a los nombres de los archivos creados por este script
MARCA="_panchuz"


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
function generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	# IFS='': Internal Field Separator, se incluye para ganarantizar que el texto sea interpretado como una única variable
	# en lugar de un vector (por lo que entiendo)
	cat <<-EOF
	# creado por (BASH_SOURCE):\t"${BASH_SOURCE}"
	# fecha y hora:\t$(date +%F_%T_TZ:%Z)
	# nombre del host:\t$(hostname)
	# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
	#

EOF
}

# CONFIGURACIÓN LOCAL
function crear_archivo_profile_local () {
	cat >/etc/profile.d/profile${MARCA}.sh <<-EOF
	${encabezado}
	# https://wiki.debian.org/Locale#Standard
	# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale

	LANG=${LANG}
EOF
}

# CONFIGURACIÓN HUSO HORARIO
function cambiar_huso_horario () {
	# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
	timedatectl set-timezone $HUSO_HORARIO
}

#------------------FUNCIÓN PRINCIPAL------------------
function main () {
# FUNICIÓN PRINCIPAL
	local encabezado="$(generacion_encabezado_stdout)"
	# para comprobar
	printf  "encabezado:\n"
 	printf "${encabezado}"
	crear_archivo_profile_local
	cambiar_huso_horario

}

main
printf "con esto termina el script\nbye\N"
