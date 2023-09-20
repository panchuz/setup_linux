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

