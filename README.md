# linux_config_inicial
bash script aimed at first configuration for a homelab debian 12 linux container:
- utf.8
- time zone
- postfix nullmail to google account
- unnattended-upgrades with on-change mail report
- sshd port change with NoRootLogin
- admin user creation and configuration
- sshd admin user public key installation
- update, upgrade and needed packages installation
- apt cleaning and autoremoving
- reestart needed or not needed message


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

## Cargar funciones general.func.sh
```
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/general.func.sh)
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
ID_ADMIN_USER=1234
ADMIN_USER_PASSWD=
SSH_PUB_KEY_ADMIN_USER="key-type key comment"
```
