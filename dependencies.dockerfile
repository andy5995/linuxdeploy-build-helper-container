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
    xxd && \
    apt install -y --reinstall ca-certificates && \
    update-ca-certificates -f

# Cmake dependencies
RUN \
  apt install -y \
    librhash-dev \
    libcurl4-openssl-dev \
    libarchive-dev \
    libjsoncpp-dev \
    libuv1-dev

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
WORKDIR /home/builder

# This would get downloaded during the linuxdeploy cmake config,
# but we'll do it here to potentially help things along
RUN \
  git clone --depth=1 --branch v.3.3.3 https://github.com/GreycLab/CImg && \
  mv CImg/CImg.h /usr/include && \
  rm -rf CImg

USER builder

ARG CMAKE_VER=3.28.3
RUN \
  curl -LO https://github.com/Kitware/CMake/releases/download/v$CMAKE_VER/cmake-$CMAKE_VER.tar.gz && \
  tar xvf cmake-$CMAKE_VER.tar.gz && \
  cd cmake-$CMAKE_VER && \
  ./bootstrap \
    --prefix=/home/builder/.local \
    --system-libs \
    --no-system-cppdap \
    --parallel=$(nproc) && \
  make -j $(nproc) && make install && \
  cd .. && rm -rf cmake-"$CMAKE_VER"*

# So pip will not report about the path...
ENV PATH=/home/builder/.local/bin:$PATH
RUN python3 -m pip install pip --upgrade --user

# On arm/v7, pip can't install cmake from source, which is needed to build ninja
RUN python3 -m pip install meson ninja --upgrade --user

USER root
