#!/usr/bin/env bash

set -e
# set -x

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [ ! -d origin ]; then
    echo "Origin Repository is not set up yet. Run setup-origin once"
    exit 1
fi

configure() {
    cmake ../origin -DENABLE_CAPNP=0 -DUSE_STATIC_LIBRARIES=0 -DSPLIT_SHARED_LIBRARIES=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DADD_GDB_INDEX_FOR_GOLD=1 -DENABLE_BROTLI=0 -DENABLE_POCO_MONGODB=0 -DENABLE_POCO_REDIS=0 -DENABLE_PARQUET=0 -DENABLE_ORC=0 -DENABLE_SSL=0 -DENABLE_CRYPTO=0 -DPOCO_SKIP_OPENSSL_FIND=1 -DENABLE_PROTOBUF=0 -DENABLE_GPERF=0 -DENABLE_BASE64=0 -DENABLE_HYPERSCAN=0 -DENABLE_RAPIDJSON=0 -DENABLE_HDFS=0 -DENABLE_CAPNP=0 -DENABLE_RDKAFKA=0 -DENABLE_MYSQL=0 -DENABLE_POCO_ODBC=0 -DENABLE_ODBC=0 -DENABLE_EMBEDDED_COMPILER=0 -DENABLE_UTILS=0 -DARCH_NATIVE=1 -DENABLE_TESTS=0
}
mkdir -p build-ori
cd build-ori

rebuild=0
if [ -f build.ninja ]; then
    echo "Incremental build is possible."
else
    rebuild=1
fi

if [ $rebuild -eq 1 ] || [ "$(basename "$0")" = "r" ]; then
    echo "Rebuild from scratch is required (needed). Are you sure? [Enter to continue, Ctrl-C to quit]"
    read -r
    echo

    rm -rf ./*

    configure
fi

ninja
