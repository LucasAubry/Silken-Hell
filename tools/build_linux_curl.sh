#!/bin/sh
# Run inside Alpine with /work mounted at the repository root.
set -eu
apk add --no-cache build-base xz openssl-dev=3.5.9-r0 openssl-libs-static=3.5.9-r0 zlib-dev=1.3.2-r1 zlib-static=1.3.2-r1 musl-dev=1.2.5-r12
mkdir -p /tmp/curl-build
tar -xJf /work/dist/downloads/curl-8.22.0.tar.xz -C /tmp/curl-build --strip-components=1
cd /tmp/curl-build
LDFLAGS="-static" LIBS="-lssl -lcrypto -lz -pthread" ./configure \
 --disable-shared --enable-static --with-openssl --disable-ldap --disable-ldaps \
 --without-libpsl --without-libidn2 --without-brotli --without-zstd --without-libssh2 \
 --without-nghttp2 --without-nghttp3 --without-librtmp --disable-manual \
 --disable-docs --disable-libcurl-option --with-ca-bundle=/etc/ssl/cert.pem
make -j2
mkdir -p /work/dist/linux-network/licenses
cp src/curl /work/dist/linux-network/curl
cp COPYING /work/dist/linux-network/licenses/curl.txt

# Preserve the exact bundled TLS dependency versions for future updates.
apk info -v openssl-dev openssl-libs-static zlib-dev zlib-static > /work/dist/linux-network/dependencies.txt
strip /work/dist/linux-network/curl
