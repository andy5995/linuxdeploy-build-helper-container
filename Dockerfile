FROM ubuntu:focal
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install -y \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    curl \
    desktop-file-utils \
    fuse \
    gettext \
    gpg \
    git \
    libcairo-dev \
    libfuse2 \
    libfuse-dev \
    libgcrypt-dev \
    libglib2.0-dev \
    libgpgme-dev \
    libjpeg-dev \
    libpng-dev \
    libssl-dev \
    libtool \
    patchelf \
    python3-pip \
    sudo \
    wget \
    xxd

RUN python3 -m pip install meson ninja

# https://apt.kitware.com/
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1A127079A92F09ED
# RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
# RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null
# RUN apt update  && \
#  apt-get install kitware-archive-keyring && \
#  apt install -y cmake
# The following signatures couldn't be verified because the public key is not
# available: NO_PUBKEY 1A127079A92F09ED

RUN useradd -m builder && passwd -d builder
RUN echo "builder ALL=(ALL) ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

# So pip will not report about the path...

ENV PATH=/home/builder/.local/bin:$PATH
RUN python3 -m pip install pip --upgrade --user
# pip can't install cmake, which is needed to build ninja, on arm/v7

ARG TARGETARCH
ARG TARGETVARIANT
RUN echo $TARGETARCH $TARGETVARIANT
RUN \
  if [ "$TARGETVARIANT" != "v7" ]; then \
    python3 -m pip install cmake --upgrade --user && \
    python3 -m pip install meson ninja --upgrade --user; \
  else \
    sudo apt install -y cmake meson ninja-build; \
  fi

RUN \
  git clone --depth 1 --branch 1-alpha-20240109-1 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
    cmake . -G Ninja && ninja && ninja install linuxdeploy && cd .. && \
    rm -rf linuxdeploy
RUN \
  git clone --depth 1 --branch 1-alpha-20230713-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . -G Ninja && ninja && ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage
RUN \
  git clone --depth 1 --branch 13 https://github.com/AppImage/AppImageKit --recurse-submodules && \
    cd AppImageKit && \
    cmake . && make -j $(nproc) && make install && cd .. && \
    rm -rf AppImageKit
RUN wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/blob/master/linuxdeploy-plugin-gtk.sh

RUN useradd -m builder && passwd -d builder
RUN echo "builder ALL=(ALL) ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

ENV DOCKER_BUILD=TRUE

CMD ["/bin/bash","-l"]
