os_arch="$1"
if ["$os_arch" == ""];then
    os_arch="x86_64";
fi

echo $os_arch

export TRAVIS_BUILD_DIR=/$PWD/libtorrent4j
echo $TRAVIS_BUILD_DIR
cd $TRAVIS_BUILD_DIR
git submodule update --depth=1 --init --recursive
export LIBTORRENT_ROOT=$PWD/swig/deps/libtorrent


git clone --depth=1 --branch=boost-1.73.0 https://github.com/boostorg/boost.git
cd boost
git submodule update --depth=1 --init --recursive
./bootstrap.sh
./b2 headers
cd ..
export BOOST_ROOT=$PWD/boost


if [ ! -d "$PWD/android-ndk-r21d" ]; then
    wget -nv -O android-ndk.zip https://dl.google.com/android/repository/android-ndk-r21d-linux-x86_64.zip;
    unzip -qq android-ndk.zip;
fi

export NDK=$PWD/android-ndk-r21d;
$NDK/build/tools/make_standalone_toolchain.py --arch $os_arch --api 21 --stl libc++ --install-dir android-toolchain;
export ANDROID_TOOLCHAIN=$PWD/android-toolchain;
sed -i 's/24/21/g' $ANDROID_TOOLCHAIN/sysroot/usr/include/ifaddrs.h;
sed -i 's/24/21/g' $ANDROID_TOOLCHAIN/sysroot/usr/include/stdio.h;
sed -i 's/28/21/g' $ANDROID_TOOLCHAIN/sysroot/usr/include/sys/random.h;

if [ ! -d "$PWD/openssl-1.1.1g" ]; then
    wget -nv -O openssl.tar.gz https://www.openssl.org/source/openssl-1.1.1g.tar.gz;
    tar xzf openssl.tar.gz;
fi

export OPENSSL_SOURCE=$PWD/openssl-1.1.1g
export OPENSSL_NO_OPTS="no-deprecated no-shared no-makedepend -fno-strict-aliasing -fvisibility=hidden -O3"

if [ "${os_arch}" == "arm" ]; then
    export CC=$ANDROID_TOOLCHAIN/bin/arm-linux-androideabi-clang;
    export run_openssl_configure="./Configure linux-armv4 ${OPENSSL_NO_OPTS} -march=armv7-a -mfpu=neon -fPIC --prefix=$OPENSSL_SOURCE/../openssl";
fi

if [ "${os_arch}" == "arm64" ]; then
    export CC=$ANDROID_TOOLCHAIN/bin/aarch64-linux-android-clang;
    export run_openssl_configure="./Configure linux-aarch64 ${OPENSSL_NO_OPTS} -march=armv8-a+crypto -fPIC --prefix=$OPENSSL_SOURCE/../openssl";
fi

if [ "${os_arch}" == "x86" ]; then
    export CC=$ANDROID_TOOLCHAIN/bin/i686-linux-android-clang;
    export run_openssl_configure="./Configure linux-elf ${OPENSSL_NO_OPTS} -fPIC --prefix=$OPENSSL_SOURCE/../openssl";
fi

if [ "${os_arch}" == "x86_64" ]; then
    export CC=$ANDROID_TOOLCHAIN/bin/x86_64-linux-android-clang;
    export run_openssl_configure="./Configure linux-x86_64 ${OPENSSL_NO_OPTS} -fPIC --prefix=$OPENSSL_SOURCE/../openssl";
fi

if [ "${os_arch}" == "arm"]; then
    export run_bjam="${BOOST_ROOT}/b2 -j2 --user-config=config/android-arm-config.jam variant=release toolset=clang-linux-arm target-os=android location=bin/release/android/armeabi-v7a";
    export run_objcopy="${ANDROID_TOOLCHAIN}/bin/arm-linux-androideabi-objcopy --only-keep-debug bin/release/android/armeabi-v7a/libtorrent4j.so bin/release/android/armeabi-v7a/libtorrent4j.so.debug";
    export run_strip="${ANDROID_TOOLCHAIN}/bin/arm-linux-androideabi-strip --strip-unneeded -x -g bin/release/android/armeabi-v7a/libtorrent4j.so";
    export run_readelf="${ANDROID_TOOLCHAIN}/bin/arm-linux-androideabi-readelf -d bin/release/android/armeabi-v7a/libtorrent4j.so";
    export PATH=$ANDROID_TOOLCHAIN/arm-linux-androideabi/bin:$PATH;
    sed -i 's/RANLIB = ranlib/RANLIB = "${ANDROID_TOOLCHAIN}\/bin\/arm-linux-androideabi-ranlib"/g' ${BOOST_ROOT}/tools/build/src/tools/gcc.jam;
fi

if [ "${os_arch}" == "arm64"]; then
    export run_bjam="${BOOST_ROOT}/b2 -j2 --user-config=config/android-arm64-config.jam variant=release toolset=clang-arm64 target-os=android location=bin/release/android/arm64-v8a";
    export run_objcopy="${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android-objcopy --only-keep-debug bin/release/android/arm64-v8a/libtorrent4j.so bin/release/android/arm64-v8a/libtorrent4j.so.debug";
    export run_strip="${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android-strip --strip-unneeded -x bin/release/android/arm64-v8a/libtorrent4j.so";
    export run_readelf="${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android-readelf -d bin/release/android/arm64-v8a/libtorrent4j.so";
    export PATH=$ANDROID_TOOLCHAIN/aarch64-linux-android/bin:$PATH;
    sed -i 's/RANLIB = ranlib/RANLIB = "${ANDROID_TOOLCHAIN}\/bin\/aarch64-linux-android-ranlib"/g' ${BOOST_ROOT}/tools/build/src/tools/gcc.jam;
fi

if [ "${os_arch}" == "x86"]; then
    export run_bjam="${BOOST_ROOT}/b2 -j2 --user-config=config/android-x86-config.jam variant=release toolset=clang-x86 target-os=android location=bin/release/android/x86";
    export run_objcopy="${ANDROID_TOOLCHAIN}/bin/i686-linux-android-objcopy --only-keep-debug bin/release/android/x86/libtorrent4j.so bin/release/android/x86/libtorrent4j.so.debug";
    export run_strip="${ANDROID_TOOLCHAIN}/bin/i686-linux-android-strip --strip-unneeded -x -g bin/release/android/x86/libtorrent4j.so";
    export run_readelf="${ANDROID_TOOLCHAIN}/bin/i686-linux-android-readelf -d bin/release/android/x86/libtorrent4j.so";
    export PATH=$ANDROID_TOOLCHAIN/i686-linux-android/bin:$PATH;
    sed -i 's/RANLIB = ranlib/RANLIB = "${ANDROID_TOOLCHAIN}\/bin\/i686-linux-android-ranlib"/g' ${BOOST_ROOT}/tools/build/src/tools/gcc.jam;
fi

if [ "${os_arch}" == "x86_64"]; then
    export run_bjam="${BOOST_ROOT}/b2 -j2 --user-config=config/android-x86_64-config.jam variant=release toolset=clang-x86_64 target-os=android location=bin/release/android/x86_64";
    export run_objcopy="${ANDROID_TOOLCHAIN}/bin/x86_64-linux-android-objcopy --only-keep-debug bin/release/android/x86_64/libtorrent4j.so bin/release/android/x86_64/libtorrent4j.so.debug";
    export run_strip="${ANDROID_TOOLCHAIN}/bin/x86_64-linux-android-strip --strip-unneeded -x bin/release/android/x86_64/libtorrent4j.so";
    export run_readelf="${ANDROID_TOOLCHAIN}/bin/x86_64-linux-android-readelf -d bin/release/android/x86_64/libtorrent4j.so";
    export PATH=$ANDROID_TOOLCHAIN/x86_64-linux-android/bin:$PATH;
    sed -i 's/RANLIB = ranlib/RANLIB = "${ANDROID_TOOLCHAIN}\/bin\/x86_64-linux-android-ranlib"/g' ${BOOST_ROOT}/tools/build/src/tools/gcc.jam;
fi

cd $OPENSSL_SOURCE
$run_openssl_configure
echo "Compiling openssl...(remove &> /dev/null to see output)"
make &> /dev/null
make install_sw &> /dev/null
cd ..
export OPENSSL_ROOT=$PWD/openssl

cd swig
$run_bjam
$run_objcopy
$run_strip
$run_readelf
cd ..