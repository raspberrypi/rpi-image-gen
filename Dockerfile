# =========================
# Dockerfile: rpi-image-gen ARM64 Builds
# =========================

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# 1️⃣ System-Tools installieren
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    bc \
    parted \
    rsync \
    locales \
    python3 \
    python3-pip \
    python3-setuptools \
    fakeroot \
    make \
    gcc \
    g++ \
    pkg-config \
    dosfstools \
    mtools \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2️⃣ QEMU ARM64 aktivieren
RUN update-binfmts --enable qemu-aarch64

# 3️⃣ Arbeitsverzeichnis
WORKDIR /pi-gen

# 4️⃣ rpi-image-gen kopieren
COPY . .


RUN ["sudo ./install_deps.sh"]

# 5️⃣ Default Command: beide Configs bauen
CMD ["bash","-c","./rpi-image-gen build -c ./config/trixie-minbase.yaml"]
