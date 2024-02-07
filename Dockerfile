FROM andy5995/linuxdeploy:dependencies-latest
USER builder
WORKDIR /home/builder

RUN \
  git clone --depth 1 --branch 1-alpha-20240109-1 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
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
RUN wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/blob/master/linuxdeploy-plugin-gtk.sh

USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install -y \
    libgtk2.0-dev \
    libgtk-3-dev \
    qt5-default

ENV DOCKER_BUILD=TRUE

USER builder
WORKDIR /home/builder

CMD ["/bin/bash","-l"]
