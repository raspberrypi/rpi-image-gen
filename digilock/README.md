# Digilock Image Generator

This repository is designed for generating customized Raspberry Pi OS images for Digilock projects. It is forked from the **Raspberry-Pi-Image-Gen** repository.

> **Note:** For the smoothest experience, clone this repository directly onto a Raspberry Pi running Raspberry Pi OS. This minimizes setup time. You can also use **VS Code Remote Development** to connect and edit files on the Pi.

---

## Repository Overview

All Digilock-specific configurations are located in the `digilock` directory.  
You do **not** need to modify files outside of this directory.

This repository supports two projects:

1. **On-Prem Demo Unit** – Based on the `slim` example. *In progress*
2. **Raspberry Pi OS–Based Kiosk** – Based on the `webkiosk` example. *In progress*

---

## On-Prem Demo Unit Setup

To build the **On-Prem Demo Unit** image:

1. **Obtain the output files** from the following GitHub Action:  
[NL-On-Prem-Auth – build-rpi.yml](https://github.com/SecurityPeopleInc/NL-On-Prem-Auth/actions/workflows/build-rpi.yml)

2. **Copy the output contents** to the following path in this repository:

   ```bash
   /rpi-image-gen/digilock/onprem-demo-slim/device/mypi5/device/
   └── rootfs-overlay/
       └── opt/
           └── digilink-onprem-demo/
               ├── auth.tar
               ├── backend.tar
               ├── config/
               │   ├── config-fe.json
               │   └── config.json
               ├── docker-compose.yml
               ├── docker-compose.demo.yml
               ├── frontend.tar
               ├── nginx.tar
               ├── nginx.conf
               ├── postgres.tar
               ├── redis.tar
               └── start.sh
