# setup_linux
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


## Download setup_linux.sh and source it (inside the OS)
```
export GITHUB_BRANCH=test && \
    wget -qP /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_linux.sh && \
    source /root/setup_linux.sh
```

## Download setup_zerotier.sh and source it (inside the OS)
```
export GITHUB_BRANCH=test && \
    wget -qP /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_zerotier.sh && \
	source /root/setup_zerotier.sh
```

## Download setup_zerotier.sh and source it (inside the OS)
```
export GITHUB_BRANCH=test && \
    wget -qP /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_cloudflare.sh && \
	source /root/setup_cloudflare.sh
```

## Load general.func.sh
```
export GITHUB_BRANCH=test && \
    source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/general.func.sh)
```

## Download setup_linux.sh and execute locally
## does not change LANG enviroment varible
```
export GITHUB_BRANCH=test
wget -P /root https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/setup_linux.sh 
chmod +x /root/setup_linux.sh
/root/setup_linux.sh
```

### setup_linux.vars.sh file format
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
