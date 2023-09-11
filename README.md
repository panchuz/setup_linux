# linux_config_inicial
script para configurar linux: utf.8 / zona horaria / etc etc etc

## Comando para correr en la consola 
## referencia: tteck
bash -c "$(wget -qLO - https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh)"

## Comando para bajar el .sh y ejecutarlo localmente
## no modifica enviroment (e.g.:LANG)
wget -P /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh
chmod +x /root/linux_config_inicial.sh
/root/linux_config_inicial.sh

## Comando para bajar el .sh y ejecutarlo como "source"
wget -qP /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh &&
source /root/linux_config_inicial.sh passwd_link_args

## Cargar funciones generales.func.sh
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

### Formato del archivo de Argumentos para linux_config_inicial.sh
#variable=contenido
MARCA="_marca"
LANG="C.utf8"
TZ="America/Argentina/Buenos_Aires"
CUENTA_GOOGLE=cuenta
GMAIL_APP_PASSWD=abcdefghijklmnop
PUERTO_SSHD=12345
NUEVO_USUARIO=alguien
PASSWD_NUEVO_USUARIO=
SSH_PUBLIC_KEY="tipo key cometario"

