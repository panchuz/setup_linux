
## To create a zerotier ct
```
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$github_branch/zerotier/ct_create_zerotier.sh) 200
```

panchuz@zt:~$ sudo nft list ruleset
table inet filter {
        chain input {
                type filter hook input priority filter; policy accept;
        }

        chain forward {
                type filter hook forward priority filter; policy accept;
        }

        chain output {
                type filter hook output priority filter; policy accept;
        }
}
table ip zt-nat {
        chain post {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "eth0" masquerade
        }
}
panchuz@zt:~$ 

nftables cheat sheet:

Load rules: nft -f /etc/sysconfig/nftables.conf (this will append them to the existing ones, so flushing first might be required)
Watch rules: nft list ruleset
Reset rules: nft flush ruleset
Speaking of your request:

nft list ruleset | grep dport

Since tables and chains can be called pretty much anything, it's kinda hard to devise a script which will list only rules for type filter hook input.