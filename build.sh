#!/bin/bash

patch_src() {
	local fullname="$1"
	local name="${1%%-*}"
	if [[ -d "patches/$name" ]]; then
		for f in "patches/$name"/*.patch; do
			patch -p1 -N --dry-run --silent -d "$fullname" < "$f"
			if [[ $? -eq 0 ]]; then
				patch -p1 -d "$fullname" < "$f"
				if [[ $? -ne 0 ]]; then
					return 1
				fi

			fi
		done
	fi
}

build_src() {
	local name="${1%%-*}"
	cd "$1"
	eval "build_$name"
	cd ..
}

download_src() {
	local url="$1"
	local name="$(basename "$url" ".tar.gz")"
	if ! [ -d "$name" ]; then
		curl -sL "$url" | tar -xzf -
		patch_src "$name"
	fi
}

build() {
	local url="$1"
	local name="$(basename "$url" ".tar.gz")"
	download_src "$url"
	build_src "$name"
}

build_freetype() {
	./configure --prefix=$BUILD_DIR \
		--with-zlib=no --with-bzip2=no --with-png=no \
		--with-harfbuzz=no --with-brotli=no --enable-static=no
	make -j"$JOBCOUNT" install
}

build_expat() {
	./configure --prefix=$BUILD_DIR \
		--without-xmlwf --without-examples --without-tests --without-docbook
	make -j"$JOBCOUNT" install
}

build_fontconfig() {
	PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig \
	CFLAGS=-static-libgcc CXXFLAGS=-static-libstdc++ \
	meson build --prefix=$BUILD_DIR \
		-Ddoc=disabled -Dnls=disabled \
		-Dtests=disabled -Dtools=enabled -Dfc-cache=disabled
	ninja -C build install
}

if [[ -d "build" ]]; then rm -rf build; fi
mkdir build
BUILD_DIR="$PWD/build"
JOBCOUNT=`nproc`

build "https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.gz"
build "https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.gz"
build "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.94.tar.gz"

# strip everything
for f in "$BUILD_DIR/bin"/*{.dll,.exe}; do
	strip --strip-unneeded "$f"
done

# since windows cannot use symlinks (at least by default for a lot of people)
for f in "$BUILD_DIR/etc/fonts"/*.conf; do
	rpath="$(readlink -e "$f")"
	rm -f "$f"
	mv "$rpath" "$f"
done

mv "$BUILD_DIR" fontconfig
mv fontconfig/share/fontconfig/conf.avail fontconfig/etc/fonts/conf.avail
rm -rf fontconfig/{include,lib,share}

zip -r fontconfig.zip fontconfig/
