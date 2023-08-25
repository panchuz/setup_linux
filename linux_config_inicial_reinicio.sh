#!/usr/bin/env bash
#source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# creado por panchuz
# para automatizar la segunda parte de la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE


#------------------FUNCIÓN PRINCIPAL------------------
function principal () {
	# aca va el comentario
 	now=$(date)
	printf "Current date and time in Linux %s\n" "$now" > /root/prueba_reinicio.txt
	printf  "%s se está ejecutando:\n" ${BASH_SOURCE} >> /root/prueba_reinicio.txt
}

principal
