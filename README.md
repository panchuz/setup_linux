# linux_config_inicial
script para configurar linux: utf.8 / zona horaria / etc etc etc


## Comando para bajar el .sh y ejecutarlo localmente
## no modifica enviroment (e.g.:LANG)
```
wget -P /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh 
chmod +x /root/linux_config_inicial.sh
/root/linux_config_inicial.sh passwd_link_args
```

## Comando para bajar el .sh y ejecutarlo como "source"
```
wget -qP /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh &&
source /root/linux_config_inicial.sh passwd_link_args
```

## Cargar funciones generales.func.sh
```
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)
```

### Formato del archivo de Argumentos para linux_config_inicial.sh
```
#variable_name=variable_content
MARK="_mark"
LANG="C.utf8"
TZ="America/Argentina/Buenos_Aires"
GOOGLE_ACCOUNT=account_name
GMAIL_APP_PASSWD=abcdefghijklmnop
SSHD_PORT=12345
ADMIN_USER=anyone
ADMIN_USER_PASSWD=
SSH_PUBLIC_KEY="key-type key comment"
```
