FROM andy5995/linuxdeploy:dependencies-latest
USER builder
WORKDIR /home/builder

RUN \
  git clone --depth 1 --branch 1-alpha-20240109-1 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
    # On arm/v7, wget fails if --no-check-certificate isn't used
    sed -i 's/wget --quiet \"$url\" -O -/curl -o - \"$url\"/g' src/core/generate-excludelist.sh && \
    cmake . \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local \
      -DBUILD_TESTING=OFF \
      -DINSTALL_GTEST=OFF \
      -DBUILD_GMOCK=OFF && \
    ninja && ninja install linuxdeploy && cd .. && \
    rm -rf linuxdeploy
RUN \
  git clone --depth 1 --branch 1-alpha-20230713-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . -G Ninja -DCMAKE_INSTALL_PREFIX=$HOME/.local && ninja && ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage
RUN \
  git clone --depth 1 --branch 13 https://github.com/AppImage/AppImageKit --recurse-submodules && \
  cd AppImageKit && \
  cmake . \
    -DCMAKE_INSTALL_PREFIX=$HOME/.local \
    -DBUILD_GMOCK=OFF \
    -DBUILD_TESTING=OFF && \
  make -j $(nproc) && make install && \
  cd .. && rm -rf AppImageKit

WORKDIR /home/builder/.local/bin
RUN \
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/3b67a1d1c1b0c8268f57f2bce40fe2d33d409cea/linuxdeploy-plugin-gtk.sh && \
  chmod +x linuxdeploy-plugin-gtk.sh

USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install -y \
    libgtk2.0-dev \
    libgtk-3-dev \
    nlohmann-json3-dev \
    qt5-default

USER builder
WORKDIR /home/builder
RUN \
  git clone \
    --branch 1-alpha-20240109-1 \
    --depth 1 \
    https://github.com/linuxdeploy/linuxdeploy-plugin-qt \
    --recurse-submodules && \
  cd linuxdeploy-plugin-qt && \
  # On arm/v7, wget fails if --no-check-certificate isn't used
  sed -i 's/wget --quiet \"$url\" -O -/curl -o - \"$url\"/g' lib/linuxdeploy/src/core/generate-excludelist.sh && \
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

