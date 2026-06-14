ARG CODENAME=jammy
FROM ubuntu:$CODENAME
ARG CODENAME=jammy

ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install --no-install-recommends -y \
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
    gnupg \
    imagemagick \
    libcairo-dev \
    libcurl4-gnutls-dev \
    libfuse2 \
    libfuse-dev \
    libgcrypt-dev \
    libglib2.0-dev \
    libgpgme-dev \
    libjpeg-dev \
    libpng-dev \
    libssl-dev \
    libtool \
    libzstd-dev \
    patchelf \
    python3-pip \
    software-properties-common \
    sudo \
    wget \
    xxd \
    zsync && \
  update-ca-certificates -f && \
  rm -rf /var/lib/apt/lists

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

RUN \
  export CODENAME=$CODENAME && \
  test -f /usr/share/doc/kitware-archive-keyring/copyright || \
  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $CODENAME main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
  sudo apt update && \
  sudo apt install -y kitware-archive-keyring && \
  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $CODENAME-rc main" | sudo tee -a /etc/apt/sources.list.d/kitware.list >/dev/null && \
  sudo apt update && \
  # The linuxdeploy cmake requires 3.2, but compatibility with CMake < 3.5 has been
  # removed from CMake as of 4.0.0
  UBUNTU_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2) && \
  VERSION="3.31.6-0kitware1ubuntu${UBUNTU_VERSION}.1" && \
  sudo apt-get update && \
  sudo apt-get install -y cmake=${VERSION} cmake-data=${VERSION} && \
  sudo apt-mark hold cmake cmake-data && \
  sudo rm -rf /var/lib/apt/lists

# So pip will not report about the path...
ENV PATH=/home/builder/.local/bin:$PATH
RUN \
  python3 -m pip install pip --upgrade --user && \
  python3 -m pip install meson ninja --upgrade --user

WORKDIR /home/builder

RUN \
  git clone --depth 1 --branch 1-alpha-20251107-1 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
    cmake . \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local \
      -DBUILD_TESTING=OFF \
      -DINSTALL_GTEST=OFF \
      -DBUILD_GMOCK=OFF \
      -DCMAKE_BUILD_TYPE=Release && \
    ninja && ninja install linuxdeploy && cd .. && \
    rm -rf linuxdeploy
RUN \
  git clone --depth 1 --branch 1-alpha-20250213-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local \
      -DCMAKE_BUILD_TYPE=Release && \
    ninja && ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage

ARG CODENAME
RUN \
  git clone --depth 1 --branch 1.9.1 https://github.com/AppImage/appimagetool.git && \
  cd appimagetool && \
  cmake . \
    -DCMAKE_INSTALL_PREFIX=$HOME/.local \
    -DCMAKE_BUILD_TYPE=Release && \
  make install && \
  sed -i 's@wget https://github.com/plougher/squashfs-tools/archive/refs/tags/"$version".tar.gz -qO - | tar xvz --strip-components=1@curl -sL https://github.com/plougher/squashfs-tools/archive/refs/tags/"$version".tar.gz | tar xvz --strip-components=1@' ci/install-static-mksquashfs.sh && \
  sudo bash -euxo pipefail ci/install-static-mksquashfs.sh 4.6.1 && \
  cd .. && rm -rf appimagetool

# Pin the AppImage type2 runtime. appimagetool hardcodes the rolling
# 'continuous' tag and only --runtime-file overrides it, so bundle a pinned,
# checksum-verified runtime for this image's arch. Bump TYPE2_RUNTIME_TAG and
# the SHAs together. TARGETARCH is provided automatically by BuildKit.
ARG TARGETARCH
ARG TYPE2_RUNTIME_TAG=20251108
RUN \
  case "$TARGETARCH" in \
    amd64) rt=runtime-x86_64;  sha=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d ;; \
    arm64) rt=runtime-aarch64; sha=00cbdfcf917cc6c0ff6d3347d59e0ca1f7f45a6df1a428a0d6d8a78664d87444 ;; \
    *) echo "Unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
  esac && \
  mkdir -p /home/builder/.local/share/appimage-runtime && \
  curl -fL "https://github.com/AppImage/type2-runtime/releases/download/${TYPE2_RUNTIME_TAG}/${rt}" \
    -o /home/builder/.local/share/appimage-runtime/runtime && \
  echo "${sha}  /home/builder/.local/share/appimage-runtime/runtime" | sha256sum -c -

# Wrap appimagetool so the bundled runtime is the default (covers both the
# linuxdeploy appimage plugin, which calls appimagetool from PATH, and direct
# appimagetool use), while still honouring an explicit --runtime-file.
RUN \
  mv /home/builder/.local/bin/appimagetool /home/builder/.local/bin/appimagetool.real && \
  printf '%s\n' \
    '#!/bin/sh' \
    'for a in "$@"; do' \
    '  case "$a" in --runtime-file|--runtime-file=*) exec /home/builder/.local/bin/appimagetool.real "$@" ;; esac' \
    'done' \
    'exec /home/builder/.local/bin/appimagetool.real --runtime-file /home/builder/.local/share/appimage-runtime/runtime "$@"' \
    > /home/builder/.local/bin/appimagetool && \
  chmod +x /home/builder/.local/bin/appimagetool

WORKDIR /home/builder/.local/bin
RUN \
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/3b67a1d1c1b0c8268f57f2bce40fe2d33d409cea/linuxdeploy-plugin-gtk.sh && \
  chmod +x linuxdeploy-plugin-gtk.sh

USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && \
  apt install --no-install-recommends -y \
    libgtk2.0-dev \
    libgtk-3-dev \
    nlohmann-json3-dev \
    qtbase5-dev && \
  rm -rf /var/lib/apt/lists

USER builder
WORKDIR /home/builder
RUN \
  git clone \
    --branch 1-alpha-20250213-1 \
    --depth 1 \
    https://github.com/linuxdeploy/linuxdeploy-plugin-qt \
    --recurse-submodules && \
  cd linuxdeploy-plugin-qt && \
  cmake . \
    -G Ninja \
    -DBUILD_GMOCK=OFF \
    -DBUILD_TESTING=OFF \
    -DINSTALL_GTEST=OFF \
    -DCMAKE_INSTALL_PREFIX=$HOME/.local && \
  ninja && ninja install && \
  cd .. && rm -rf linuxdeploy-plugin-qt

ENV DOCKER_BUILD=TRUE
USER root
WORKDIR /
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
