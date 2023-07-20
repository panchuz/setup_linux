#!/bin/bash

# creado por panchuz
# para automatizar la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE

marca="_panchuz"


function script_directorio_nombre_stdout () {
	# determinación del directorio de este script para que conste en el encabezado
	# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
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

function generacion_encabezado () {
# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN

	script_directorio_nombre="$(script_directorio_nombre_stdout)"

	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	# IFS='': Internal Field Separator, se incluye para ganarantizar que el texto sea interpretado como una única variable
	# en lugar de un vector (por lo que entiendo)
	IFS='' read -r -d '' encabezado <<-EOF
	# creado por "$(script_directorio_nombre_stdout)"
	# fecha y hora: $(date +%F_%T_TZ:%Z)
	# nombre del host: $(hostname)
	# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
	#
	EOF
}

function generacion_encabezado_stdout () {
# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN

	script_directorio_nombre="$(script_directorio_nombre_stdout)"

	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	# IFS='': Internal Field Separator, se incluye para ganarantizar que el texto sea interpretado como una única variable
	# en lugar de un vector (por lo que entiendo)
	printf "# creado por: \t\t$(script_directorio_nombre_stdout)\n"
	printf "# fecha y hora: \t$(date +%F_%T_TZ:%Z)\n"
	printf "# nombre del host: \t$(hostname)\n"
	printf "# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)\n"
	printf "#\n"
}

echo "$(generacion_encabezado_stdout)"

funcion crear_archivo_profile_local () {
# CONFIGURACIÓN LOCAL 
# ref:

	cat >/etc/profile.d/profile${marca}.sh <<-EOF
	${encabezado}
	# https://wiki.debian.org/Locale#Standard
	# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_the_reconfiguration_of_the_locale

	LANG=C.utf8
	EOF
}

# CONFIGURACIÓN HUSO HORARIO
# ref

funcion crear_archivo_profile_local_stdout () {
#
}
