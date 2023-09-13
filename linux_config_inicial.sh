#!/usr/bin/env bash
passwd_link_args_aes256="$1" # passwd para desencriptar link_args.aes256

#######################################################################
#  creado por panchuz                                                 #
#  para automatizar la configuración inicial de lxc generado en base  #
#  al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE  #
#######################################################################

# verificación de la cantidad de argumentos
if [ $# -ne 1 ]; then
	echo "Uso: $BASH_SOURCE passwd_link_args_aes256"
	return 1
fi

# carga de biblioteca de funciones generales
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# Opciones para la configuración
#export LANG=C.utf8 # quedará de forma permamente. Ver: crear_archivo_profile_local ()
#export TZ='America/Argentina/Buenos_Aires'

# el contenido de la sig variable sirve para appendear a los nombres de los archivos creados por este script
#MARCA="_panchuz"

# resto de las variables se definen en función principal


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	cat <<-EOF
		# creado por (BASH_SOURCE):	${BASH_SOURCE}
		# fecha y hora:	$(date +%F_%T_TZ:%Z)
		# nombre host:	$(hostname)
		# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
		#
		
	EOF
}

# CONFIGURACIÓN LOCAL
crear_archivo_profile_locale () {
	cat >/etc/profile.d/profile${MARCA}.sh <<-EOF
		${encabezado}
		# https://wiki.debian.org/Locale#Standard
		# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale
	
		LANG=${LANG}
	EOF
}

# CONFIGURACIÓN HUSO HORARIO
# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
config_huso_horario () {
	timedatectl set-timezone ${TZ}
}

# --- CONFIGURACIÓN postfix ---
# https://www.postfix.org/STANDARD_CONFIGURATION_README.html#null_client	y ...#fantasy
# https://www.lynksthings.com/posts/sysadmin/mailserver-postfix-gmail-relay/
# https://forum.proxmox.com/threads/get-postfix-to-send-notifications-email-externally.59940/
# https://serverfault.com/questions/744761/postfix-aliases-will-be-ignored
# https://www.computernetworkingnotes.com/linux-tutorials/how-to-configure-a-postfix-null-client-step-by-step.html
# https://unix.stackexchange.com/questions/1449/lightweight-outgoing-smtp-server/731560#731560
config_postfix_nullclient_gmail () {
	systemctl stop postfix
	# sasl_passwd: guarda las credenciales para usar el SMTP server de Gmail
	cat >/etc/postfix/sasl/sasl_passwd <<-EOF
		${encabezado}
		# https://www.lynksthings.com/posts/sysadmin/mailserver-postfix-gmail-relay/
		#
		[smtp.gmail.com]:587 ${CUENTA_GOOGLE}@gmail.com:${GMAIL_APP_PASSWD}
	EOF
	postmap /etc/postfix/sasl/sasl_passwd
	chmod 0600 /etc/postfix/sasl/sasl_passwd*
	
	# backup de la configuración original
	cp /etc/postfix/main.cf /etc/postfix/main.cf.ORIGINAL${MARCA}
	
	# configuración postfix >> /etc/postfix/main.cf
	# smtp_generic_maps mapea usuarios locales a direcciones de mail
	# smtp_header_checks modifica el header para que From: sea lindo
	postconf 'mydestination =' \
		'relayhost = [smtp.gmail.com]:587' \
		'inet_interfaces = loopback-only' \
		'compatibility_level = 3.6' \
		'smtp_tls_security_level = encrypt' \
		'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' \
		'smtp_sasl_security_options = noanonymous' \
		'smtp_sasl_auth_enable = yes' \
		'smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd' \
		"smtp_generic_maps = pcre:{{/(.*)@\$myorigin/ $CUENTA_GOOGLE+\$\${1}%$(hostname)@gmail.com}}" \
		"smtp_header_checks = pcre:{{/^From:.*/ REPLACE From: $(hostname) <myorigin-@-\$myorigin>}}"
	systemctl start postfix
}


# --- CONFIGURACIÓN unattended-upgrades PRUEBA MAIL ---
config_unattended-upgrades_prueba_mail () {

	cat >/etc/apt/apt.conf.d/51unattended-upgrades${MARCA} <<-EOF
		Unattended-Upgrade::Mail "root";
		Unattended-Upgrade::MailReport "always"; /* SOLO PARA PROBAR */
	EOF

	unattended-upgrade && echo "Checkear recepción de mail de unattended-upgrades"

	# ${encabezado//\#///} subtituye "#" por "//". Ref: https://stackoverflow.com/a/43421455
	cat >/etc/apt/apt.conf.d/51unattended-upgrades${MARCA} <<-EOF
		${encabezado//\#///}
		// https://wiki.debian.org/UnattendedUpgrades#Unattended_Upgrades
		// 
		Unattended-Upgrade::Mail "root";
		Unattended-Upgrade::MailReport "on-change";
	EOF
}


# --- AGREGADO Y CONFIGURACIÓN USUARIO panchuz ---
agregar_usuario_admin () {
	nuevo_usuario=$1
	id_nuevo_usuario=$2
	passwd_nuevo_usuario="$3"
	ssh_pub_key_nuevo_usuario="$4"

	useradd --uid ${id_nuevo_usuario} \
		--shell /bin/bash \
		--create-home \
		--groups sudo,systemd-journal,adm \
		${nuevo_usuario}
	echo "$nuevo_usuario:$passwd_nuevo_usuario" | chpasswd

	# Para poder hacer ping http://unixetc.co.uk/2016/05/30/linux-capabilities-and-ping/
	setcap cap_net_raw+p $(which ping)

	# crea el archivo de la clave ssh pública del usuario
	local nuevo_usuario_sshkey_dir="$(eval echo "~${nuevo_usuario}")/.ssh"
	mkdir "$nuevo_usuario_sshkey_dir"
	cat >"$nuevo_usuario_sshkey_dir"/authorized_keys${MARCA} <<-EOF
		${encabezado}
		# http://man.he.net/man5/authorized_keys
		#
		${ssh_pub_key_nuevo_usuario}
	EOF
	chown --recursive "${nuevo_usuario}:${nuevo_usuario}" "$nuevo_usuario_sshkey_dir"
	chmod 600 "$nuevo_usuario_sshkey_dir"/*
}


# --- CONFIGURACIÓN sshd ---
configuracion_sshd () {
	# $1 puerto sshd

	cat >/etc/ssh/sshd_config.d/sshd_config${MARCA}.conf <<-EOF
		${encabezado}
		# http://man.he.net/man5/sshd_config
		#
		Port $1
		PermitRootLogin no
		AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2 .ssh/authorized_keys${MARCA}
		PasswordAuthentication no
	EOF
	systemctl reload sshd
}


# --- CREA UN service PARA CONTINUAR LUEGO DEL REINICIO ---
# https://wiki.debian.org/systemd#Creating_or_altering_services
# $1: El service creado ejecuta $1 luego del reinicio
crear_reinicio-service () {
	local path_script_reinicio="$1"
 	
  	local nombre_reinicio_service=reinicio${MARCA}.service
 	local path_nombre_reinicio_service=/etc/systemd/system/${nombre_reinicio_service}
  
 	cat >${path_nombre_reinicio_service} <<-EOF
		${encabezado}
		# https://wiki.debian.org/systemd#Creating_or_altering_services
		# https://operavps.com/docs/run-command-after-boot-in-linux/
	 
		[Unit]
		Description=Ejecuta ${path_script_reinicio} por única vez luego de reinicio
		After=network.target auditd.service
		ConditionFileIsExecutable=${path_script_reinicio}
	
		[Service]
		Type=oneshot
		ExecStart=/bin/bash ${path_script_reinicio}
		# desactiva el servicio luego que cumplió su función:
		ExecStartPost=/bin/systemctl disable ${nombre_reinicio_service} 
	
		[Install]
		WantedBy=multi-user.target
	EOF
	systemctl enable ${nombre_reinicio_service}
}

#------------------FUNCIÓN PRINCIPAL------------------
principal () {
	passwd_link_args_eas256="$1"

	#carga de argumentos
	wget --quiet https://github.com/panchuz/linux_config_inicial/raw/main/link_args.aes256
	link_args=$(desencript_stdout "$(cat link_args.aes256)" $passwd_link_args_eas256)
	source <(wget --quiet -O - --no-check-certificate "$link_args")

  	# script para seguir el proceso luego del reboot (o del no reboot)
   	# debe coincidir con el de https://github.com/panchuz/linux_config_inicial/raw/main/....sh
	local script_reinicio=linux_config_inicial_reinicio.sh
 	local path_script_reinicio=/root/${script_reinicio}
  
	wget -qO ${path_script_reinicio} https://github.com/panchuz/linux_config_inicial/raw/main/${script_reinicio}
	if [ $? -eq 0 ]; then
		chmod +x ${path_script_reinicio}
	else
		echo "ABORTANDO: No se pudo descargar ${script_reinicio}"
   		return 1
	fi

 	# Setea huso horario
	config_huso_horario
 
	# genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado="$(generacion_encabezado_stdout)"
  
  	# genera locale $LANG permanente
	crear_archivo_profile_locale
 
 	# Actualización desatendida "confdef/confold"
	# mailx es pedido en /etc/apt/apt.conf.d/50unattended-upgrades para notificar por mail
	# apt-listchanges es indicado en https://wiki.debian.org/UnattendedUpgrades#Automatic_call_via_.2Fetc.2Fapt.2Fapt.conf.d.2F20auto-upgrades
	debian_dist-upgrade_install libsasl2-modules postfix-pcre bsd-mailx apt-listchanges unattended-upgrades sudo
	##### rsyslog: https://itslinuxfoss.com/find-postfix-log-files/

	# configurar postfix como nullclient/smtp de gmail/no-FQDN:
	# usa $CUENTA_GOOGLE y $GMAIL_APP_PASSWD
	config_postfix_nullclient_gmail
 
 	# configurar uanttended-upgrades
	config_unattended-upgrades_prueba_mail

	# agregado usuario panchuz
	# si no se proporcionó PASSWD_NUEVO_USUARIO, se usa passwd_link_args_eas256 en su lugar
	if [ -n "$PASSWD_NUEVO_USUARIO" ]; then
		agregar_usuario_admin $NUEVO_USUARIO $ID_NUEVO_USUARIO $PASSWD_NUEVO_USUARIO "$SSH_PUB_KEY_NUEVO_USUARIO"
	else
		agregar_usuario_admin $NUEVO_USUARIO $ID_NUEVO_USUARIO $passwd_link_args_eas256 "$SSH_PUB_KEY_NUEVO_USUARIO"
	fi

	# configuración ssh
	configuracion_sshd $PUERTO_SSHD

 	# reboot necesario????
 	if [ -f /var/run/reboot-required ]; then
		crear_reinicio-service "$path_script_reinicio"
  		echo "Se procede a reiniciar"
		/bin/sleep 5
		reboot
 	else
 		echo "NO se necesita reiniciar"
   		${path_script_reinicio}
  	fi
}

# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( $EUID == 0 )); then
	principal "$passwd_link_args_aes256"
else
	echo "ERROR: Este script se debe ejecutar con privilegios root"
fi
