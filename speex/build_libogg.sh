#!/bin/sh

#
# Build libogg for iOS.
#
# Xcode with command line tool installed, iOS 6.1, iOS 7.1, OSX 10.9 SDK required.
#
# Elf Sundae, www.0x123.com
# Jul 14, 2014
#

LIB="libogg"
LIB_VERSION="1.3.2"
LIB_DIR=${LIB}-${LIB_VERSION}
DEVELOPER_ROOT=`xcode-select -print-path`
CURRENT_PATH=`pwd`
BUILD_PATH=${CURRENT_PATH}/build
BIN_PATH=${BUILD_PATH}/${LIB_DIR}
LIBFILES=""
BUILD="x86_64-apple-darwin"

ARCHS=("i386" "x86_64" "armv7" "armv7s" "arm64")
# ARCHS=("i386")

if [ ! -d "${LIB_DIR}" ]; then
	file="${LIB_DIR}.tar.gz"
	if [ ! -f "${file}" ]; then
		set -x
		curl -O http://downloads.xiph.org/releases/ogg/${file}
		set +x
	fi
	tar jxf $file
fi

cd ${LIB_DIR}

for ARCH in ${ARCHS[@]}
do
	if [ "${ARCH}" == "i386" ]; then
		PLATFORM="iPhoneSimulator"
		HOST="i386-apple-darwin"
		SDK_VERSION="6.1"
	elif [ "${ARCH}" == "x86_64" ]; then
		PLATFORM="MacOSX"
		HOST="x86_64-apple-darwin"
		SDK_VERSION="10.9"
	else
		PLATFORM="iPhoneOS"
		HOST="arm-apple-darwin"
		SDK_VERSION="7.1"
	fi

	SDK=${DEVELOPER_ROOT}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk
	PREFIX=${BUILD_PATH}/${LIB}/${ARCH}

	rm -rf "${PREFIX}"
	mkdir -p "${PREFIX}"

	export CFLAGS="-arch ${ARCH} -isysroot ${SDK}"
	export CC="${DEVELOPER_ROOT}/usr/bin/gcc ${CFLAGS}"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$CFLAGS"
	export LD=$CC

	./configure --prefix="${PREFIX}" --host=${HOST} --build=${BUILD} --disable-shared --enable-static
	make clean
	make && make install

	echo "=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*"
	libfile=${PREFIX}/lib/${LIB}.a
	if [ ! -f "${libfile}" ]; then
		echo "${ARCH} Error."
		exit -1
	fi

	lipo -info "${libfile}"
	echo "=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*"

	LIBFILES="${libfile} ${LIBFILES}"
done
echo ""

libfile=${BIN_PATH}/lib/${LIB}.a

rm -rf "${BIN_PATH}"
mkdir "${BIN_PATH}"
# copy headers
cp -r "${BUILD_PATH}/${LIB}/${ARCHS[0]}/include/" "${BIN_PATH}/include/"
# create fat libraries
mkdir "${BIN_PATH}/lib"
lipo -create ${LIBFILES} -output "${libfile}"

if [ ! -f "${libfile}" ]; then
	echo "lipo Error."
	exit -1
fi
# check architectures information
lipo -info "${libfile}"

# copy to precompiled directory
PRECOMPILED_PATH=${CURRENT_PATH}/precompiled/${LIB_DIR}
rm -rf "${PRECOMPILED_PATH}"
mkdir -p "${PRECOMPILED_PATH}"
cp -a "${BIN_PATH}/include/" "${PRECOMPILED_PATH}"
cp -a "${libfile}" "${PRECOMPILED_PATH}"

echo "=*= Done =*="