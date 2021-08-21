#!/bin/bash

if ! [ -d "freetype-2.11.0" ]; then
	curl -sL https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz | xz -d | tar -xf -
fi
if ! [ -d "fontconfig-2.13.94" ]; then
	curl -sL https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.94.tar.xz | xz -d | tar -xf -
fi

if ! [ -d "expat-2.4.1" ]; then
	curl -sL https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.xz | xz -d | tar -xf -
fi

if ! [ -d "build" ]; then mkdir build; fi
BUILD_DIR=$PWD/build

cd freetype-2.11.0
./configure --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no --enable-static=no --prefix=$BUILD_DIR
make && make install
cd ..

cd expat-2.4.1
./configure --prefix=$BUILD_DIR --without-xmlwf --without-examples --without-tests --without-docbook
make && make install
cd ..

cd fontconfig-2.13.94

patch -p1 -N --dry-run --silent < ../patches/fc-cache-opt.diff 2>/dev/null
if [[ $? -eq 0 ]]; then
	patch -p1 < ../patches/fc-cache-opt.diff
fi

PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig CFLAGS=-static-libgcc CXXFLAGS=-static-libstdc++ meson build -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=enabled -Dfc-cache=disabled --prefix=$BUILD_DIR
ninja -C build install
cd ..

# strip everything
for f in build/bin/*.dll; do
	strip --strip-unneeded "$f"
done

tar -czf artifact.tar.gz build/
