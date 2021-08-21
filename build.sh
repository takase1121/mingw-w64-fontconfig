#!/bin/bash

if ! [ -d "freetype-2.11.0" ]; then
	curl -SL https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz | xz -d | tar -xf -
fi
if ! [ -d "fontconfig-2.13.94" ]; then
	curl -SL https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.94.tar.xz | xz -d | tar -xf -
fi

if ! [ -d "build" ]; then mkdir build; fi
BUILD_DIR=$PWD/build

cd freetype-2.11.0
./configure --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no --enable-static=no --prefix=$BUILD_DIR
make && make install
cd ..
cd fontconfig-2.13.94

patch -p1 -N --dry-run --silent < ../patches/fc-cache-opt.diff 2>/dev/null
if [[ $? -eq 0 ]]; then
	patch -p1 < ../patches/fc-cache-opt.diff
fi

PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig CFLAGS=-static-libgcc CXXFLAGS=-static-libstdc++ meson build -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=enabled -Dfc-cache=disabled --prefix=$BUILD_DIR
ninja -C build install

tar -czf artifact.tar.gz build/
