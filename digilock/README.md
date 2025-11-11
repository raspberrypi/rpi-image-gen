# Digilock Image Generator

This repository is designed for generating customized Raspberry Pi OS images for Digilock projects. It is forked from the **Raspberry-Pi-Image-Gen** repository.

> **Note:** For the smoothest experience, clone this repository directly onto a Raspberry Pi running Raspberry Pi OS to act as the Image Generator and the Imager. This minimizes setup time. You can also use **VS Code Remote Development** to connect and edit files on the Pi.

---

## Repository Overview

All Digilock-specific configurations are located in the `digilock` directory.  
You do **not** need to modify files outside of this directory.

This repository supports two projects:

1. **On-Prem Demo Unit** – Based on the `slim` example. *In progress*
2. **Raspberry Pi OS–Based Kiosk** – Based on the `webkiosk` example. *In progress*

---

## Set Up Dev Environment for building images and flashing

### 1. Requirements

- **Two Raspberry Pis:**
  - **Host Pi:** used for building/flashing (Pi 4 or 5 recommended)
  - **Target Pi (CM5):** the On-Prem Demo Unit
- USB-C cable (for flashing)
- Jumper

#### Install Dependencies on the Host Pi

```bash
sudo apt update
sudo apt install rpiboot rpi-imager
```
> Note: You may also need to install the following additional dependencies:  
`genimage`, `mtools`, `mmdebstrap`, `bdebstrap`, `podman`, `pv`, `uidmap`, `btrfs-progs`, `dctrl-tools`, `uuid-runtime`, and `python3-debian`.  

You can install them on Debian-based systems by running:  

```bash
sudo apt update
sudo apt install -y genimage mtools mmdebstrap bdebstrap podman pv uidmap btrfs-progs dctrl-tools uuid-runtime python3-debian

```

---

### 2. Clone and Prepare Repository

Clone this repository to the Host Pi:

```bash
cd ~
git clone https://github.com/SecurityPeopleInc/rpi-image-gen.git
cd rpi-image-gen
```

Then obtain the **output artifacts** from the following GitHub Action:  
[NL-On-Prem-Auth – build-rpi.yml](https://github.com/SecurityPeopleInc/NL-On-Prem-Auth/actions/workflows/build-rpi.yml)

Transfer the tar file to the raspberry pi you will use for building the image. 
extract the tar file using 
`tar -xzvf digilink-onprem-vX.X.X.tar.gz`
and put them into this structure: IMPORTANT!

```
rpi-image-gen/digilock/onprem-demo-slim/device/mypi5/device/rootfs-overlay/opt/digilink-onprem-demo/
├── auth.tar
├── backend.tar
├── config/
│   ├── config-fe.json
│   └── config.json
├── docker-compose.yml
├── docker-compose.demo.yml
├── frontend.tar
├── nginx.tar
├── nginx.demo.conf
├── postgres.tar
├── redis.tar
└── start.demo.sh
```
> **Note:** . Depending on how you transferred the output files to your directory, the start.demo.sh script may have lost its executable permission (especially if copied from a Windows file system, which does not preserve Unix file permissions).
`chmod +x rpi-image-gen/digilock/onprem-demo-slim/device/mypi5/device/rootfs-overlay/opt/digilink-onprem-demo/start.demo.sh`

> You might need read and write permissions to run the images. You can use `sudo chown -R "$USER":"$USER" rpi-image-gen` and `chmod -R u+rwX rpi-image-gen` to give permissions to your user.

---

## On-Prem Demo Unit Setup

This guide explains how to build and flash the **On-Prem Demo Unit** image using one Raspberry Pi (the *Host*) to flash another (the *Target* Compute Module 5, or CM5).

---

### 1. Build the Image

```bash
cd ~/rpi-image-gen
```
Now you have a choice between two configuration files for two different images.
```bash
# Standard Image that contains just the onprem-demo as a server and a minimal standard network install utilizing an external DHCP server and no DNS.  
./rpi-image-gen build -S ./digilock/onprem-demo-slim/ -c pi5-onprem-demo.yaml
```
OR
```bash
# This build uses the custom network to create an access point and have the pi act as a dns server and dhcp server for connecting a controller and tablet without the need for an external network. Creates an access point with SSID DigiLinkOnPremDemo
./rpi-image-gen build -S ./digilock/onprem-demo-slim/ -c pi5-onprem-demo-network.yaml

```

The `.img` file will appear in:

```bash
~/rpi-image-gen/work/image-onprem-demo-dhcp/onprem-demo-dhcp.img
```

```bash
~/rpi-image-gen/work/image-onprem-demo-network/onprem-demo-network.img
```
---

###  2. Flash the Compute Module 5

#### Step 1 — Connect
1. Power off the CM5.
2. Add the jumper to CM5 **disable CM5 eMMC boot**.
3. Connect CM5 to the Host Pi via USB-C.

#### Step 2 — Mount the eMMC
On the build/flash Raspberry Pi

Run:
```bash
sudo rpiboot
```
Wait for the eMMC to appear as a drive (e.g. `/dev/sda`).

#### Step 3 — Flash with Raspberry Pi Imager

Use the rpi-imager cli tool to flash the board:

```bash
sudo rpi-imager --cli ./work/image-onprem-demo-network-INTERNAL/onprem-demo-network-INTERNAL.img /dev/sda
```
OR
```bash
sudo rpi-imager --cli ./work/image-onprem-demo-INTERNAL/onprem-demo-dhcp-INTERNAL.img /dev/sda
```
---

### 3. Boot and Connect
If you are using the onprem-demo-network.img (static IP),  Navigate to the static IP (192.168.8.1) in a browser tab on the client device: 192.168.8.1:8080; You should see DigiLink running.

If you are using the onprem-demo-dhcp.img (DHCP), Navigate the IP address the Pi was assigned in a browser tab on the client device; You should see DigiLink running.

If you want to manually determine the IP address of the RPI from DHCP, login to the Pi using the credentials defined in `digilock/onprem-demo-slim/config` (default logins are u: zippy p: Fo0bar!! & u: root p: Fo0bar!!) and run: 

```bash
cat /proc/net/fib_trie
```
---

### 4. Removing Old Builds
Over time, the images in your work directory can accumulate and consume most of the available storage on your Raspberry Pi.
To free up space for future builds, simply remove the directories ending with "-dirty" in the `rpi-image-gen/work` directory — these contain temporary or incomplete build data that are safe to delete.
