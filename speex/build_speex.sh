#!/bin/sh
#
#
# Build Speex for iOS and OS X.
#
# Require Xcode installed with command line tool.
#
# Elf Sundae, www.0x123.com
#
# 2014-07-14	Create script.
# 2016-07-19	Automatically detect sdk versions.
#

LIB="speex"
LIB_VERSION="1.2rc1"
OGG="libogg-1.3.2"
LIB_DIR=${LIB}-${LIB_VERSION}
DEVELOPER_ROOT=`xcode-select -print-path`
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_PATH=${CURRENT_PATH}/build
BIN_PATH=${CURRENT_PATH}/precompiled/${LIB_DIR}
OGG_PATH=${CURRENT_PATH}/precompiled/${OGG}
LIBFILES=""
LIBFILES_DSP=""
BUILD="x86_64-apple-darwin"
ARCHS=("i386" "x86_64" "armv7" "armv7s" "arm64")

IOS_SDK_VERSION=$(/usr/bin/xcodebuild -showsdks | sed -e '/./{H;$!d;}' -e 'x;/iOS SDKs/!d;' | grep -o '[0-9]*\.[0-9]* ' | xargs);
IOS_SIMULATOR_SDK_VERSION=$(/usr/bin/xcodebuild -showsdks | sed -e '/./{H;$!d;}' -e 'x;/iOS Simulator SDKs/!d;' | grep -o '[0-9]*\.[0-9]* ' | xargs);
OSX_SDK_VERSION=$(/usr/bin/xcodebuild -showsdks | sed -e '/./{H;$!d;}' -e 'x;/OS X SDKs/!d;' | grep -o '[0-9]*\.[0-9]* ' | xargs);

cd "${CURRENT_PATH}"

if [ ! -f "${OGG_PATH}/lib/libogg.a" ]; then
	sh ./build_libogg.sh
fi

if [ ! -d "${LIB_DIR}" ]; then
	file="${LIB_DIR}.tar.gz"
	if [ ! -f "${file}" ]; then
		set -x
		curl -O http://downloads.xiph.org/releases/speex/${file}
		set +x
	fi
	tar jxf $file
fi

cd "${LIB_DIR}"

for ARCH in ${ARCHS[@]}
do
	if [ "${ARCH}" == "i386" ]; then
		PLATFORM="iPhoneSimulator"
		HOST="i386-apple-darwin"
		SDK_VERSION="$IOS_SIMULATOR_SDK_VERSION"
	elif [ "${ARCH}" == "x86_64" ]; then
		PLATFORM="MacOSX"
		HOST="x86_64-apple-darwin"
		SDK_VERSION="$OSX_SDK_VERSION"
	else
		PLATFORM="iPhoneOS"
		HOST="arm-apple-darwin"
		SDK_VERSION="$IOS_SDK_VERSION"
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

	./configure --prefix="${PREFIX}" --host=${HOST} --build=${BUILD} \
		--disable-shared --enable-static \
			-disable-oggtest -enable-fixed-point -disable-float-api \
				--with-ogg="${OGG_PATH}"

	make clean
	make && make install

	libfile="${PREFIX}/lib/lib${LIB}.a"
	if [ ! -f "${libfile}" ]; then
		echo "${ARCH} Error."
		exit -1
	fi

	# lipo -info "${libfile}"
	LIBFILES="${libfile} ${LIBFILES}"
	LIBFILES_DSP="${PREFIX}/lib/lib${LIB}dsp.a ${LIBFILES_DSP}"
done
echo ""

rm -rf "${BIN_PATH}"
mkdir "${BIN_PATH}"
# copy headers
cp -r "${BUILD_PATH}/${LIB}/${ARCHS[0]}/include/" "${BIN_PATH}/include/"
# create fat libraries
mkdir "${BIN_PATH}/lib"
lipo -create ${LIBFILES} -output "${BIN_PATH}/lib/lib${LIB}.a"
lipo -create ${LIBFILES_DSP} -output "${BIN_PATH}/lib/lib${LIB}dsp.a"
# check architectures information
# lipo -info "${BIN_PATH}/lib/lib${LIB}.a"
# lipo -info "${BIN_PATH}/lib/lib${LIB}dsp.a"

# build framework
FRAMEWORK_NAME="speex" # use lower-case to prevent from #include issue
FRAMEWORK_PATH=${CURRENT_PATH}/precompiled/${FRAMEWORK_NAME}.framework

rm -rf "${FRAMEWORK_PATH}"
mkdir -p "${FRAMEWORK_PATH}/Versions/A/Headers"

ln -sfh A "${FRAMEWORK_PATH}/Versions/Current"
ln -sfh Versions/Current/Headers "${FRAMEWORK_PATH}/Headers"
ln -sfh "Versions/Current/${FRAMEWORK_NAME}" "${FRAMEWORK_PATH}/${FRAMEWORK_NAME}"
ln -sfh "Versions/Current/${FRAMEWORK_NAME}dsp" "${FRAMEWORK_PATH}/${FRAMEWORK_NAME}dsp"
cp -a "${BUILD_PATH}/${LIB}/${ARCHS[0]}/include/speex/" "${FRAMEWORK_PATH}/Versions/A/Headers"
lipo -create ${LIBFILES} -output "${FRAMEWORK_PATH}/Versions/A/${FRAMEWORK_NAME}"
lipo -create ${LIBFILES_DSP} -output "${FRAMEWORK_PATH}/Versions/A/${FRAMEWORK_NAME}dsp"

lipo -info "${FRAMEWORK_PATH}/Versions/A/${FRAMEWORK_NAME}"

echo "=*= Done =*="
