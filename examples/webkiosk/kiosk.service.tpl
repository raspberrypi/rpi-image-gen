[Unit]
Description=Kiosk Wayland Session
After=network-online.target
After=systemd-time-wait-sync.service
Requires=systemd-time-wait-sync.service
After=multi-user.target

[Service]
User=$KIOSK_USER
TTYPath=/dev/tty1
RuntimeDirectory=$KIOSK_RUNDIR_NAME
RuntimeDirectoryMode=0700
Environment="XDG_RUNTIME_DIR=/run/$KIOSK_RUNDIR_NAME"
Restart=always
ExecStart=/usr/bin/cage -- $KIOSK_APP
StandardError=journal

[Install]
WantedBy=default.target
