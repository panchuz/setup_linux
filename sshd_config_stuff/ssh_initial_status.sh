Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Aug 29 19:18:49 UTC 2023 on tty1
root@deb12:~# systemctl status ssh
* ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Tue 2023-10-03 14:27:53 UTC; 38s ago
TriggeredBy: * ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 156 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 162 (sshd)
      Tasks: 1 (limit: 18841)
     Memory: 4.9M
        CPU: 24ms
     CGroup: /system.slice/ssh.service
             `-162 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Oct 03 14:27:53 deb12 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Oct 03 14:27:53 deb12 sshd[162]: Server listening on :: port 22.
Oct 03 14:27:53 deb12 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.


root@deb12:~# systemctl status ssh.socket
* ssh.socket - OpenBSD Secure Shell server socket
     Loaded: loaded (/lib/systemd/system/ssh.socket; enabled; preset: enabled)
     Active: active (running) since Tue 2023-10-03 14:27:49 UTC; 57s ago
   Triggers: * ssh.service
     Listen: [::]:22 (Stream)
     CGroup: /system.slice/ssh.socket

Oct 03 14:27:49 deb12 systemd[1]: Listening on ssh.socket - OpenBSD Secure Shell server socket.


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
root@deb12:~# 