#!/usr/bin/env bash

set -e
# set -x

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "$1" in
"dev")
    bdir=build-dev
    configure="cmake .. -DUSE_STATIC_LIBRARIES=0 -DSPLIT_SHARED_LIBRARIES=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_BROTLI=0 -DENABLE_POCO_MONGODB=0 -DENABLE_POCO_REDIS=0 -DENABLE_PARQUET=0 -DENABLE_ORC=0 -DENABLE_SSL=0 -DENABLE_CRYPTO=0 -DPOCO_SKIP_OPENSSL_FIND=1 -DENABLE_PROTOBUF=0 -DENABLE_GPERF=0 -DENABLE_BASE64=0 -DENABLE_HYPERSCAN=0 -DENABLE_RAPIDJSON=0 -DENABLE_HDFS=0 -DENABLE_CAPNP=0 -DENABLE_RDKAFKA=0 -DENABLE_MYSQL=0 -DENABLE_POCO_ODBC=0 -DENABLE_ODBC=0 -DUSE_EMBEDDED_COMPILER=0 -DENABLE_UTILS=0 -DARCH_NATIVE=1 -DENABLE_TESTS=0"
    ;;

"rel")
    bdir=build-rel
    configure="cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DENABLE_EMBEDDED_COMPILER=1 -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DCMAKE_EXE_LINKER_FLAGS=-Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2"
    ;;
"ub")
    bdir=build-ub
    configure="cmake .. -DENABLE_ICU=0 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DSANITIZE=undefined -DENABLE_EMBEDDED_COMPILER=1 -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_TESTS=0 -DENABLE_UTILS=0 -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_EXE_LINKER_FLAGS=-Wl,--dynamic-linker,/lib64/ld-linux-x86-64.so.2"
    ;;
*)
    echo "Usage: $0 <dev|rel|ub>"
    exit 1
    ;;
esac

if [ -d build ] && [ ! -h build ]
then
    echo "A real directory named 'build' should not exist. Remove it manually then proceed again."
    exit 1
fi

rebuild=0
if [ -f build/build.ninja ] && [ "$(basename "$(readlink -f build)")" = "$bdir" ]
then
    echo "Incremental build is possible."
    cd build
else
    rebuild=1
fi


if [ $rebuild -eq 1 ] || [ "$(basename "$0")" = "r" ]; then
    read -p "Rebuild from scratch is required (needed). Are you sure? [Enter to continue, Ctrl-C to quit]" -n 1 -r
    echo

    ln -sfT "$bdir" build
    cd build
    rm -rf ./*

    $configure
fi

ninja
