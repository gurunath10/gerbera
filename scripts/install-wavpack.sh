#!/usr/bin/env bash
set -Eeuo pipefail

. $(dirname "${BASH_SOURCE[0]}")/versions.sh

VERSION="${WAVPACK-5.4.0}"
UNAME=$(uname)

if [ "$(id -u)" != 0 ]; then
    echo "Please run this script with superuser access!"
    exit 1
fi

#script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
script_dir=`pwd -P`
src_dir="${script_dir}/wavpack-${VERSION}"
tgz_file="${script_dir}/wavpack-${VERSION}.tar.xz"

BUILD_SHARED=YES

if [ $# -gt 0 ]; then
    if [ "$1" = "static" ]; then
        BUILD_SHARED=NO
    fi
fi

if [ ! -f "${tgz_file}" ]; then
    wget https://github.com/dbry/WavPack/releases/download/${VERSION}/wavpack-${VERSION}.tar.xz -O "${tgz_file}"
#    https://github.com/dbry/WavPack/releases/download/${VERSION}/wavpack-${VERSION}.tar.xz
fi

if [ -d "${src_dir}" ]; then
    rm -r ${src_dir}
fi
mkdir "${src_dir}"

tar -xvf "${tgz_file}" --strip-components=1 -C "${src_dir}"

cd "${src_dir}"

if [ -d build ]; then
    rm -R build
fi
mkdir build
cd build

cmake .. -DBUILD_SHARED_LIBS=${BUILD_SHARED}
../configure \
    --disable-asm \
    --enable-man \
    --enable-rpath \
    --disable-tests \
    --disable-apps \
    --enable-dsd \
    --enable-legacy

if command -v nproc >/dev/null 2>&1; then
    make "-j$(nproc)"
else
    make
fi

make install

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != 'alpine' ]; then
        ldconfig
    fi
fi
