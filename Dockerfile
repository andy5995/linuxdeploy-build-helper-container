FROM ubuntu:focal
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install -y \
    autoconf \
    automake \
    build-essential \
    curl \
    desktop-file-utils \
    fuse \
    gettext \
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

RUN \
  mkdir build-cmake && cd build-cmake && \
  wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v3.26.5/cmake-3.26.5.tar.gz && \
  tar xf cmake-3.26.5.tar.gz && \
  cd cmake-3.26.5 && \
  ./bootstrap && make -j $(nproc) && make install && \
  cd ../.. && \
  rm -rf build-cmake

RUN useradd -m builder && passwd -d builder
RUN echo "builder ALL=(ALL) ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

# So pip will not report about the path...
ENV PATH=/home/builder/.local/bin:$PATH

RUN python3 -m pip install pip --upgrade --user
RUN python3 -m pip install meson ninja --upgrade --user

RUN \
  git clone --depth 1 --branch 1-alpha-20240109-1 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
    cmake . -G Ninja && ninja && sudo ninja install linuxdeploy && cd .. && \
    rm -rf linuxdeploy
RUN \
  git clone --depth 1 --branch 1-alpha-20230713-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . -G Ninja && ninja && sudo ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage
RUN \
  git clone --depth 1 --branch 13 https://github.com/AppImage/AppImageKit --recurse-submodules && \
    cd AppImageKit && \
    cmake . && make -j $(nproc) && sudo make install && cd .. && \
    rm -rf AppImageKit
RUN wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/blob/master/linuxdeploy-plugin-gtk.sh

ENV DOCKER_BUILD=TRUE

CMD ["/bin/bash","-l"]
