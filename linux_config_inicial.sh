#!/usr/bin/env bash
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# creado por panchuz
# para automatizar la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE

# Opciones para la configuración
export LANG=C.utf8 # quedará de forma permamente. Ver: function crear_archivo_profile_local ()
export TZ='America/Argentina/Buenos_Aires'

# el contenido de la sig variable sirve para appendear a los nombres de los archivos creados por este script
MARCA="_panchuz"

# resto de las variables se definen en función principal


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
function generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	cat <<-EOF
	# creado por (BASH_SOURCE):\t${BASH_SOURCE}
	# fecha y hora:\t$(date +%F_%T_TZ:%Z)
	# nombre del host:\t$(hostname)
	# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
	#
	
EOF
}

# CONFIGURACIÓN LOCAL
function crear_archivo_profile_locale () {
	cat >/etc/profile.d/profile${MARCA}.sh <<-EOF
	${encabezado}
	# https://wiki.debian.org/Locale#Standard
	# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale

	LANG=${LANG}
EOF
}

# CONFIGURACIÓN HUSO HORARIO
function config_huso_horario () {
	# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
	timedatectl set-timezone ${TZ}
}



# SERVICIO PARA EL REINICIO
# https://wiki.debian.org/systemd#Creating_or_altering_services
function crear_archivo_reinicio-service () {
	cat >/etc/systemd/system/reinicio${MARCA}.service <<-EOF
	${encabezado}
	# https://wiki.debian.org/systemd#Creating_or_altering_services
	# https://operavps.com/docs/run-command-after-boot-in-linux/
 
	[Unit]
	Description=Ejecuta /root/${script_reinicio} por única vez luego de reinicio
	After=network.target auditd.service
	ConditionFileIsExecutable=/root/${script_reinicio}

	[Service]
	Type=oneshot
	ExecStart=/bin/bash /root/${script_reinicio}
	# desactiva el servicio luego que cumplió su función:
	ExecStartPost=/bin/systemctl disable reinicio${MARCA}

	[Install]
	WantedBy=multi-user.target
EOF
}

#------------------FUNCIÓN PRINCIPAL------------------
function principal () {
 	
  	# script para seguir el proceso luego del reboot (o del no reboot)
	export script_reinicio=linux_config_inicial_reinicio.sh
	wget -qP /root https://github.com/panchuz/linux_config_inicial/raw/main/${script_reinicio} &&
 		chmod +x /root/${script_reinicio}
   
        # genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado="$(generacion_encabezado_stdout)"
  
  	# genera locale $LANG permanente
	crear_archivo_profile_locale
 
 	# Setea huso horario
	config_huso_horario
 
 	# Actualización desatendida "confnew", OJO!
	debian_dist-upgrade

 	# reboot necesario????
 	if [ -f /var/run/reboot-required ]; then
		crear_archivo_reinicio-service
  		printf "Se procede a reiniciar\n"
    		/bin/sleep 3
      		reboot
 	else
 		printf "NO se necesita reiniciar\n"
   		/root/${script_reinicio}
  	fi
}

# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( $EUID == 0 )); then
	principal
else
	printf "ERROR: Este script se debe ejecutar con privilegios root\n"
fi
printf "con esto termina el script\nbye\n"
