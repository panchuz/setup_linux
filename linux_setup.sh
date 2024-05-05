#!/usr/bin/env bash
usage () { echo "Usage: ${BASH_SOURCE[0]}\nNo arguments supported"; return 1; }

#######################################################################
#  by panchuz                                                         #
#  para automatizar la configuración inicial de lxc generado en base  #
#  al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE  #
#######################################################################

# Sanity check
# ref: if command; then command; else command; fi
if ! [ $# -eq 0 ]; then { usage; return 1 }; fi

# Load general functions 
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_setup/main/general.func.sh)


# LOCALE configuration
crear_archivo_profile_locale () {
	cat >/etc/profile.d/profile"$MARK".sh <<-EOF
		$encabezado
		# https://wiki.debian.org/Locale#Standard
		# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale
	
		LANG=$LANG
	EOF
}

# CONFIGURACIÓN HUSO HORARIO
# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
config_huso_horario () {
	timedatectl set-timezone "$TZ"
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
		$encabezado
		# https://www.lynksthings.com/posts/sysadmin/mailserver-postfix-gmail-relay/
		#
		[smtp.gmail.com]:587 ${GOOGLE_ACCOUNT}@gmail.com:$GMAIL_APP_PASSWD
	EOF
	postmap /etc/postfix/sasl/sasl_passwd
	chmod 0600 /etc/postfix/sasl/sasl_passwd*
	
	# backup de la configuración original
	cp /etc/postfix/main.cf /etc/postfix/main.cf.ORIGINAL"$MARK"
	
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
		"smtp_generic_maps = pcre:{{/(.*)@\$myorigin/ $GOOGLE_ACCOUNT+\$\${1}%$(hostname)@gmail.com}}" \
		"smtp_header_checks = pcre:{{/^From:.*/ REPLACE From: $(hostname) <myorigin-@-\$myorigin>}}"
	systemctl start postfix
}


# --- CONFIGURACIÓN unattended-upgrades PRUEBA MAIL ---
config_unattended_upgrades_prueba_mail () {

	cat >/etc/apt/apt.conf.d/51unattended-upgrades"$MARK" <<-EOF
		Unattended-Upgrade::Mail "root";
		Unattended-Upgrade::MailReport "always"; /* ONLY FOR TESTING PURPOSES */
	EOF

	unattended-upgrades && echo "Check unattended-upgrades mail reception in ${GOOGLE_ACCOUNT}@gmail.com"

	# ${encabezado//\#///} subtituye "#" por "//". Ref: https://stackoverflow.com/a/43421455
	cat >/etc/apt/apt.conf.d/51unattended-upgrades"$MARK" <<-EOF
		${encabezado//\#///}
		// https://wiki.debian.org/UnattendedUpgrades#Unattended_Upgrades
		// 
		Unattended-Upgrade::Mail "root";
		Unattended-Upgrade::MailReport "on-change";
	EOF
}


# --- CONFIGURACIÓN sshd ---
sshd_configuration () {

	cat >/etc/ssh/sshd_config.d/10access"$MARK".conf <<-EOF
		$encabezado
		# http://man.he.net/man5/sshd_config
		# https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
		#
		# WARNING: As of openssh-server 1:9.0, sshd has socket-based activation
		# => the Port setting below in ONLY honored after (and if) it gets
		# reloaded, NOT at startup. The initial listening port is set at 
		# /etc/systemd/system/ssh.socket.d/*.conf
		#
		Port $SSHD_PORT
		PermitRootLogin no
		AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2 .ssh/authorized_keys$MARK
		PasswordAuthentication no
	EOF

	# now we create drop-ins for ssh.{socket,service} and loads them
	mkdir -p /etc/systemd/system/ssh.socket.d
	cat >/etc/systemd/system/ssh.socket.d/10ListenStream"$MARK".conf <<-EOF
		$encabezado
		# https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189/7
		#
		# WARNING: the Port setting below in ONLY honored from boot and UNTIL
		# sshd gets reloaded. Once relaoded, sshd listens on the port set in
		# /etc/ssh/sshd_config.d/*.conf
		#
		[Socket]
		ListenStream=
		ListenStream=$SSHD_PORT
	EOF

	# ssh.socket is stoped before reloading systemd units to avoid port usage conflict
	#systemctl stop ssh.socket
	systemctl daemon-reload

	# reload ssh.service to load the new config file without interrupting open connections
	systemctl reload ssh.service
}


#------------------FUNCIÓN main------------------
main () {
	# Load setup variables for the new ct/vm
	linux_setup_vars || return 1
	
 	# Set time zone
	config_huso_horario
 
	# genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado
	encabezado="$(encabezado_stdout)"
  
  	# genera locale $LANG permanente
	crear_archivo_profile_locale
 
 	# Actualización desatendida "confdef/confold"
	# mailx es pedido en /etc/apt/apt.conf.d/50unattended-upgrades para notificar por mail
	# apt-listchanges es indicado en https://wiki.debian.org/UnattendedUpgrades#Automatic_call_via_.2Fetc.2Fapt.2Fapt.conf.d.2F20auto-upgrades
	debian_dist_upgrade_install libsasl2-modules postfix-pcre bsd-mailx apt-listchanges unattended-upgrades sudo
	##### rsyslog: https://itslinuxfoss.com/find-postfix-log-files/

	# configurar postfix como nullclient/smtp de gmail/no-FQDN:
	# usa $GOOGLE_ACCOUNT y $GMAIL_APP_PASSWD
	config_postfix_nullclient_gmail
 
 	# configurar uanttended-upgrades
	config_unattended_upgrades_prueba_mail

	# Add administrative user
	# uses global variables:  ADMIN_USER, ID_ADMIN_USER y SSH_PUB_KEY_ADMIN_USER
	agregar_usuario_admin "$ADMIN_USER" "$ID_ADMIN_USER" "$ADMIN_USER_ENC_PASSWD" "$SSH_PUB_KEY_ADMIN_USER"

	# configuración sshd: puerto y agrega autorizedkeys con MARK
	# usa vars globales: encabezado, MARK y SSHD_PORT
	sshd_configuration

 	# reboot necesario????
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
