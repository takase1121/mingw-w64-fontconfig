#!/bin/bash

curl -L https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz | xz -d | tar -xf -
curl -L https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.94.tar.xz | xz -d | tar -xf -

cd freetype-2.11.0
./configure --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no --enable-static=no --prefix=../build
make && make install
cd ..
cd fontconfig-2.13.94
meson build -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=enabled --prefix=../build
ninja -C build install
