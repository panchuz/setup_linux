# linux_setup
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


## Download linux_setup.sh and source it
```
wget -qP /root https://github.com/panchuz/linux_setup/raw/$github_branch/linux_setup.sh && \
    source /root/linux_setup.sh passwd_link_args
```

## Download zerotier_setup.sh and source it
```
wget -qP /root https://raw.githubusercontent.com/panchuz/linux_setup/$github_branch/zerotier_setup.sh && \
	source /root/zerotier_setup.sh"
```

## Cargar funciones general.func.sh
```
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_setup/main/general.func.sh)
```

## Download linux_setup.sh and execute locally
## does not change LANG enviroment varible
```
wget -P /root https://github.com/panchuz/linux_setup/raw/main/linux_setup.sh 
chmod +x /root/linux_setup.sh
/root/linux_setup.sh
```

### Formato del archivo de Argumentos para linux_setup.sh
```
#variable_name=variable_content
MARK="_mark"

LANG="C.utf8"
TZ="Continent/Country/City"

GOOGLE_ACCOUNT=account_name
GMAIL_APP_PASSWD=abcdefghijklmnop
SSHD_PORT=12345

ADMIN_USER=anyone
ID_ADMIN_USER=1234
# openssl passwd -6 -salt $ADMIN_USER "super-cool-password"
ADMIN_USER_ENC_PASSWD=
SSH_PUB_KEY_ADMIN_USER="key-type key comment"
```
