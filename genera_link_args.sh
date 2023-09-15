#!/usr/bin/env bash
passwd_link_args_aes256=$1

if [ -n "$CODESPACE_NAME" ]; then
    source generales.func.sh
else
    source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)
fi

encript_stdout "$_LINK_ARGS" "$passwd_link_args_aes256" > link_args.aes256
