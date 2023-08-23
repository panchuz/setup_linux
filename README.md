# linux_config_inicial
script para configurar linux: utf.8 / zona horaria / etc

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
source /root/linux_config_inicial.sh

## Cargar funciones generales.func.sh
### https://github.com/panchuz/linux_config_inicial/raw/main/
bash -c "$(wget -qLO - https://github.com/panchuz/linux_config_inicial/raw/main/generales.func.sh)" 
