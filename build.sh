#!/bin/bash

curl -L https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz | xz -d | tar -xf -
curl -L https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.94.tar.xz | xz -d | tar -xf -

mkdir build
BUILD_DIR=$PWD/build

cd freetype-2.11.0
./configure --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no --enable-static=no --prefix=$BUILD_DIR
make && make install
cd ..
cd fontconfig-2.13.94
PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig meson build -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=enabled --prefix=$BUILD_DIR
ninja -C build install
