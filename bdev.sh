#!/usr/bin/env bash

set -e
# set -x

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [ ! -d src ]; then
    echo "Repository is not set up yet. Run setup once"
    exit 1
fi

type=$1
if [ -z "$type" ]; then
    bdir=$(basename "$(readlink -f build)")
    type="${bdir#build-}"
fi

arch=$(dpkg --print-architecture)

if [ "$arch" = "amd64" ]
then
   ld="/lib64/ld-linux-x86-64.so.2"
elif [ "$arch" = "arm64" ]
then
   ld="/lib/ld-linux-aarch64.so.1"
else
    echo "Only support arch = amd64|arm64. Given $arch."
    exit 1
fi

compiler_flags="-DCMAKE_C_COMPILER=/tmp/gentoo225/usr/lib/llvm/12/bin/clang -DCMAKE_CXX_COMPILER=/tmp/gentoo225/usr/lib/llvm/12/bin/clang++ -DLLVM_AR_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-ar -DLLVM_RANLIB_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-ranlib -DLINKER_NAME=/tmp/gentoo225/usr/bin/ld.lld -DOBJCOPY_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-objcopy"

common_flags="$compiler_flags -DENABLE_LIBRARIES=0 -DENABLE_HYPERSCAN=1 -DENABLE_JEMALLOC=1 -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_FASTOPS=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DUSE_SIMDJSON=1 -DENABLE_CLICKHOUSE_ALL=0 -DENABLE_CLICKHOUSE_SERVER=1 -DENABLE_CLICKHOUSE_CLIENT=1 -DENABLE_CLICKHOUSE_INSTALL=1 -DLLVM_ENABLE_ZLIB=0 -DENABLE_THINLTO=0 -DUSE_BINARY_HASH=1 -DENABLE_CLICKHOUSE_COPIER=1 -DENABLE_S3=1"

ci_flags="-DENABLE_NURAFT=1 -DENABLE_CLICKHOUSE_KEEPER=1 -DENABLE_CLICKHOUSE_ODBC_BRIDGE=1 -DENABLE_ODBC=1 -DENABLE_CLICKHOUSE_LIBRARY_BRIDGE=1"

common_flags="$common_flags $ci_flags"
# common_flags="-DUSE_DEBUG_HELPERS=1 -DCMAKE_C_COMPILER=/tmp/gentoo225/usr/lib/llvm/12/bin/clang -DCMAKE_CXX_COMPILER=/tmp/gentoo225/usr/lib/llvm/12/bin/clang++ -DLLVM_AR_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-ar -DLLVM_RANLIB_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-ranlib -DLINKER_NAME=/tmp/gentoo225/usr/bin/ld.lld -DOBJCOPY_PATH=/tmp/gentoo/usr/lib/llvm/12/bin/llvm-objcopy -DENABLE_LIBRARIES=0 -DENABLE_HYPERSCAN=1 -DENABLE_JEMALLOC=0 -DSANITIZE=undefined -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_FASTOPS=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DUSE_SIMDJSON=1 -DENABLE_CLICKHOUSE_ALL=0 -DENABLE_CLICKHOUSE_SERVER=1 -DENABLE_CLICKHOUSE_CLIENT=1 -DENABLE_THINLTO=0"

# tsan (consume a lot of memory which is not tracked by memory tracker)
# common_flags="-DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DSANITIZE=thread -DUSE_DEBUG_HELPERS=1 -DENABLE_LIBRARIES=0 -DENABLE_JEMALLOC=0 -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_FASTOPS=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DUSE_SIMDJSON=1"
# asan
# common_flags="-DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DSANITIZE=address -DUSE_DEBUG_HELPERS=1 -DENABLE_LIBRARIES=0 -DENABLE_JEMALLOC=0 -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_FASTOPS=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DUSE_SIMDJSON=1"
parquet_flags="-DENABLE_SSL=1 -DUSE_SNAPPY=1 -DENABLE_PROTOBUF=1 -DENABLE_ORC=1 -DENABLE_PARQUET=1"
hdfs_flags="-DENABLE_GSASL_LIBRARY=1 -DENABLE_HDFS=1 -DENABLE_PROTOBUF=1"
mysql_flags="-DENABLE_MYSQL=1"
kafka_flags="-DENABLE_RDKAFKA=1"
# uncomment if you need parquet build
common_flags="$common_flags $parquet_flags"
# uncomment if you need hdfs build
common_flags="$common_flags $hdfs_flags"
# uncomment if you need mysql build
common_flags="$common_flags $mysql_flags"
# uncomment if you need kafka build
common_flags="$common_flags $kafka_flags"

bdir=build-$type
if [[ $type = *-clang ]]
then
    compiler="-DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_C_COMPILER=clang-10"
    compiler="-DCMAKE_CXX_COMPILER=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/clang++ -DCMAKE_C_COMPILER=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/clang -DLINKER_NAME=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/ld.lld -DOBJCOPY_PATH=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/llvm-objcopy -DLLVM_RANLIB_PATH=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/llvm-ranlib -DLLVM_AR_PATH=/media/ssd1/clickhouse1/gentoo/home/amos/git/llvm-project/debug/bin/llvm-ar
"
else
    compiler=
fi
case "$type" in
dev* | ori*)
    if [[ $type = ori* ]]
    then
        source_dir=../origin
    else
        source_dir=../src
    fi
    function configure() {
        # cmake $source_dir -DCLICKHOUSE_SPLIT_BINARY=0 -DENABLE_REPLXX=1 -DENABLE_READLINE=1 -DUSE_DEBUG_HELPERS=1 -DUSE_SIMDJSON=0 -DENABLE_CAPNP=0 -DUSE_STATIC_LIBRARIES=0 -DSPLIT_SHARED_LIBRARIES=1 -DCMAKE_BUILD_TYPE=Debug -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_BROTLI=0 -DENABLE_PARQUET=0 -DENABLE_ORC=0 -DENABLE_PROTOBUF=0 -DENABLE_BASE64=0 -DENABLE_HYPERSCAN=0 -DENABLE_RAPIDJSON=0 -DENABLE_HDFS=0 -DENABLE_CAPNP=0 -DENABLE_RDKAFKA=0 -DENABLE_MYSQL=1 -DENABLE_ODBC=0 -DENABLE_EMBEDDED_COMPILER=0 -DENABLE_UTILS=0 -DARCH_NATIVE=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 $compiler
        cmake ../src -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DENABLE_READLINE=1 -DUSE_DEBUG_HELPERS=1 -DENABLE_CLICKHOUSE_ALL=OFF -DENABLE_CLICKHOUSE_SERVER=ON -DENABLE_CLICKHOUSE_CLIENT=ON -DENABLE_CLICKHOUSE_ODBC_BRIDGE=ON -DUSE_STATIC_LIBRARIES=OFF -DCLICKHOUSE_SPLIT_BINARY=ON -DSPLIT_SHARED_LIBRARIES=ON -DENABLE_LIBRARIES=OFF -DENABLE_UTILS=ON -DENABLE_TESTS=OFF -DENABLE_MYSQL=ON -DUSE_UNWIND=1
    }
    ;;
dbg*)
    function configure() {
        cmake ../src -DUSE_DEBUG_HELPERS=1 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Debug -DUSE_STATIC_LIBRARIES=0 -DSPLIT_SHARED_LIBRARIES=1 -DENABLE_THINLTO=0 -DENABLE_LIBRARIES=0 -DENABLE_JEMALLOC=1 -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_FASTOPS=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DUSE_SIMDJSON=1 -DENABLE_RAPIDJSON=1 -DENABLE_THINLTO=0 -DENABLE_CLICKHOUSE_ALL=0 -DENABLE_CLICKHOUSE_SERVER=1 -DENABLE_CLICKHOUSE_FORMAT=1 -DENABLE_CLICKHOUSE_CLIENT=1 -DENABLE_CLICKHOUSE_LOCAL=1 -DENABLE_S3=1 -DENABLE_SSL=1 -DENABLE_HYPERSCAN=1 -DCMAKE_CXX_FLAGS="-ggnu-pubnames -fno-limit-debug-info"
    }
    ;;
2dbg*)
    function configure() {
        cmake ../src -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Debug -DENABLE_THINLTO=0 -DCMAKE_CXX_FLAGS="-ggnu-pubnames -fno-limit-debug-info" $common_flags
    }
    ;;
kwaid)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" $common_flags -DCMAKE_BUILD_TYPE=Debug
    }
    ;;
kwaiservice)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-s -Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" $common_flags -DSANITIZE=memory -DENABLE_JEMALLOC=1 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_C_COMPILER=clang-10
    }
    ;;
jni*)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-Wl,--build-id -Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" -DENABLE_LIBRARIES=0 -DENABLE_JEMALLOC=1 -DENABLE_REPLXX=1 -DUSE_UNWIND=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DSPLIT_SHARED_LIBRARIES=1 -DMAKE_STATIC_LIBRARIES=0
    }
    ;;
kwai*)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-Wl,--build-id -Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" $common_flags
    }
    ;;
kwaimusl*)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-Wl,--build-id -Wl,--dynamic-linker,/lib/ld-musl-x86_64.so.1" $common_flags
    }
    ;;
masterd*)
    function configure() {
        cmake ../origin -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DENABLE_READLINE=1 -DUSE_DEBUG_HELPERS=1 -DCMAKE_BUILD_TYPE=Debug -DENABLE_CLICKHOUSE_ALL=OFF -DENABLE_CLICKHOUSE_SERVER=ON -DENABLE_CLICKHOUSE_CLIENT=ON -DENABLE_CLICKHOUSE_ODBC_BRIDGE=ON -DUSE_STATIC_LIBRARIES=OFF -DCLICKHOUSE_SPLIT_BINARY=ON -DSPLIT_SHARED_LIBRARIES=ON -DENABLE_LIBRARIES=OFF -DENABLE_UTILS=OFF -DENABLE_TESTS=OFF -DENABLE_MYSQL=ON -DUSE_UNWIND=1 $common_flags
    }
    ;;
master*)
    function configure() {
        cmake ../origin -DCMAKE_EXE_LINKER_FLAGS="-Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" $common_flags
    }
    ;;
rs*)
    function configure() {
        cmake ../src -DCLICKHOUSE_SPLIT_BINARY=0 -DENABLE_REPLXX=1 -DUSE_DEBUG_HELPERS=1 -DCMAKE_BUILD_TYPE=Release -DENABLE_LIBRARIES=0 -DUSE_UNWIND=1 $parquet_flag -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DENABLE_SSL=1 -DENABLE_MYSQL=1 -DCMAKE_EXE_LINKER_FLAGS="-s -Wl,--dynamic-linker,$ld" $compiler
    }
    ;;
rel*)
    function configure() {
        # cmake ../src -DUSE_UNWIND=1 -DUSE_DEBUG_HELPERS=1 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DENABLE_EMBEDDED_COMPILER=0 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DCMAKE_EXE_LINKER_FLAGS="-Wl,--dynamic-linker,$ld" $compiler
        cmake ../src -DUSE_UNWIND=1 -DUSE_DEBUG_HELPERS=1 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DENABLE_EMBEDDED_COMPILER=0 -DENABLE_TESTS=0 -DENABLE_UTILS=0  $compiler
    }
    ;;
"ub")
    function configure() {
        cmake ../src -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DSANITIZE=undefined -DENABLE_EMBEDDED_COMPILER=0 -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DENABLE_UTILS=0 -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_EXE_LINKER_FLAGS=-Wl,--dynamic-linker,$ld
    }
    ;;
uni*)
    function configure() {
        cmake ../src -DCMAKE_EXE_LINKER_FLAGS="-Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2" $compiler_flags
    }
    ;;
mem*)
    function configure() {
        cmake ../src -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu -DSANITIZE=memory -DADD_GDB_INDEX_FOR_GOLD=1 -DLINKER_NAME=lld -DENABLE_TESTS=0 -DUSE_GTEST=0 -DENABLE_UTILS=0 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_C_COMPILER=clang-10 -GNinja
    }
    ;;
*)
    echo "Usage: $0 [dev|rel|ub|uni]"
    exit 1
    ;;
esac

mkdir -p "$bdir"

# if [ -d build ] && [ ! -h build ]; then
#     echo "A real directory named 'build' should not exist. Remove it manually then proceed again."
#     exit 1
# fi


if [ $bdir != "build-ori" ]
then
    ln -sfT "$bdir" build
fi
cd "$bdir"

rebuild=0
if [ -f build.ninja ]; then
    echo "Incremental build is possible."
else
    rebuild=1
fi

if [ $rebuild -eq 1 ] || [ "$(basename "$0")" = "r" ]; then
    read -p "Rebuild from scratch is required (needed). Are you sure? [Enter to continue, Ctrl-C to quit]" -n 1 -r
    echo

    rm -rf ./*

    configure
elif [ "$(basename "$0")" = "f" ]; then
    read -p "Reconfigure?" -n 1 -r
    echo

    configure
fi

if [ "$(basename "$0")" = "bv" ]
then
   ninja -v
else
   ninja
fi
