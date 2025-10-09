# Digilock Image Gen
Clone this repository to a raspberry pi running rapsberry pi os.  This will reduce setup time.  
You can remote into the raspberry pi using vscode remote development.

All custom image generation should be done inside the digilock/ folder.

This repository will soon support two projects:

- The On-Prem Demo Unit (based on slim example)
- The Raspberry Pi OS–based Kiosk (based on webkiosk example)

To build the image file:
cd /rpi-image-gen
./rpi-image-gen build -S ./digilock/onprem-demo-slim/ -c pi5-onprem-demo.yaml

The output file will be at /work/image-onprem-demo-image/onprem-demo-image.img