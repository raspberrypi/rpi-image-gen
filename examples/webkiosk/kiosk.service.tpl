[Unit]
Description=Kiosk Wayland Session
After=systemd-time-wait-sync.service
Requires=systemd-time-wait-sync.service
After=multi-user.target

[Service]
User=$KIOSK_USER
TTYPath=/dev/tty1
Environment="XDG_RUNTIME_DIR=$KIOSK_RUNDIR"
Restart=always
ExecStart=/usr/bin/cage -- $KIOSK_APP
StandardError=journal

[Install]
WantedBy=default.target
