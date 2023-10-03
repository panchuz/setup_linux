Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Oct  3 11:18:24 -03 2023 on tty1
root@deb12:~# systemctl status ssh
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; preset: enabled)
    Drop-In: /etc/systemd/system/ssh.service.d
             └─sshd.service.conf
     Active: active (running) since Tue 2023-10-03 12:00:27 -03; 50s ago
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 148 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 154 (sshd)
      Tasks: 1 (limit: 18841)
     Memory: 4.9M
        CPU: 24ms
     CGroup: /system.slice/ssh.service
             └─154 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Oct 03 12:00:26 deb12 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Oct 03 12:00:27 deb12 sshd[154]: Server listening on :: port 31422.
Oct 03 12:00:27 deb12 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.


root@deb12:~# systemctl status ssh.socket
● ssh.socket - OpenBSD Secure Shell server socket
     Loaded: loaded (/lib/systemd/system/ssh.socket; enabled; preset: enabled)
    Drop-In: /etc/systemd/system/ssh.socket.d
             └─sshd.socket.conf
     Active: active (running) since Tue 2023-10-03 12:00:25 -03; 6min ago
   Triggers: ● ssh.service
     Listen: [::]:31422 (Stream)
     CGroup: /system.slice/ssh.socket

Oct 03 12:00:25 deb12 systemd[1]: Listening on ssh.socket - OpenBSD Secure Shell server socket.


root@deb12:~# systemctl cat ssh.{socket,service}
# /lib/systemd/system/ssh.socket
[Unit]
Description=OpenBSD Secure Shell server socket
Before=sockets.target
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Socket]
ListenStream=22
Accept=no

[Install]
WantedBy=sockets.target

# /etc/systemd/system/ssh.socket.d/sshd.socket.conf
# creado por (BASH_SOURCE):     /dev/fd/63
# fecha y hora: 2023-10-03_11:19:01_TZ:-03
# nombre host:  deb12
# Debian GNU/Linux 12 (bookworm) / kernel version 6.2.16-4-bpo11-pve
#
# https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189/7
#
# WARNING: the Port setting below in ONLY honored from boot and UNTIL
# sshd gets reloaded. Once relaoded, sshd listens on the port set in
# /etc/ssh/sshd_config.d/sshd_config"".conf
#
[Socket]
ListenStream=
ListenStream=31422

# /lib/systemd/system/ssh.service
[Unit]
Description=OpenBSD Secure Shell server
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStartPre=/usr/sbin/sshd -t
ExecStart=/usr/sbin/sshd -D $SSHD_OPTS
ExecReload=/usr/sbin/sshd -t
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=notify
RuntimeDirectory=sshd
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
Alias=sshd.service

# /etc/systemd/system/ssh.service.d/sshd.service.conf
# creado por (BASH_SOURCE):     /dev/fd/63
# fecha y hora: 2023-10-03_11:19:01_TZ:-03
# nombre host:  deb12
# Debian GNU/Linux 12 (bookworm) / kernel version 6.2.16-4-bpo11-pve
#
# https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189/7
#
# WARNING: the goal of this conf file is to prevents sshd form
# getting reloaded (systemctl reload sshd).
# Why? Because it generates a "port already in use" ERROR
# between ssh.socket and ssh.service, STOPPING sshd.
#
[Service]
ExecReload=
root@deb12:~# 


panchuz@deb12:~$ cat /etc/ssh/sshd_config.d/*.conf
# creado por (BASH_SOURCE):     /dev/fd/63
# fecha y hora: 2023-10-03_11:19:01_TZ:-03
# nombre host:  deb12
# Debian GNU/Linux 12 (bookworm) / kernel version 6.2.16-4-bpo11-pve
#
# http://man.he.net/man5/sshd_config
# https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
#
# WARNING: As of openssh-server 1:9.0, sshd has socket-based activation
# => the Port setting below in ONLY honored after (and if) it gets
# reloaded, NOT at startup. The initial listening port is set at
# /etc/systemd/system/ssh.socket.d/sshd.socket"".conf
#
# If both -service and socket- config files point to the same port,
# sshd reload will cause a "port already in use" ERROR, STOPPING sshd.
# Hence: /etc/systemd/system/ssh.service.d/sshd.service"".conf
#
Port 31422
PermitRootLogin no
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2 .ssh/authorized_keys
PasswordAuthentication no
panchuz@deb12:~$ 