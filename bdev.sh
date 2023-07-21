#!/usr/bin/env bash

set -e
# set -x

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

type=$1
if [ -z "$type" ]; then
    bdir=$(basename "$(readlink -f build)")
    type="${bdir#build-}"
else
    bdir=build-$type
fi

export APUS_TOOLCHAIN_PATH=/tmp/gentoo/home/amos/toolchain
export PATH=${APUS_TOOLCHAIN_PATH}/bin:$PATH

# thrift compiler has mem leak, which breaks asan build during code generation
export ASAN_OPTIONS=detect_leaks=0

case "$type" in
d)
    configure() {
        cmake \
           -DCMAKE_BUILD_TYPE=Debug \
           -DENABLE_TESTS=0 \
           -DENABLE_UTILS=0 \
           -DENABLE_CLICKHOUSE_ALL=0 \
           -DENABLE_CLICKHOUSE_SERVER=1 \
           -DENABLE_CLICKHOUSE_CLIENT=1 \
           -DENABLE_CLICKHOUSE_LOCAL=1 \
           -DENABLE_CLICKHOUSE_BENCHMARK=1 \
           ../src
    }
    ;;
a)
    configure() {
        cmake \
           -DSANITIZE=address \
           -DENABLE_JEMALLOC=0 \
           -DCMAKE_BUILD_TYPE=Debug \
           -DENABLE_TESTS=0 \
           -DENABLE_UTILS=0 \
           -DENABLE_CLICKHOUSE_ALL=0 \
           -DENABLE_CLICKHOUSE_SERVER=1 \
           -DENABLE_CLICKHOUSE_CLIENT=1 \
           -DENABLE_CLICKHOUSE_LOCAL=1 \
           -DENABLE_CLICKHOUSE_BENCHMARK=1 \
           ../src
    }
    ;;
r)
    configure() {
        cmake \
           -DENABLE_THINLTO=0 \
           -DENABLE_TESTS=0 \
           -DENABLE_UTILS=0 \
           -DENABLE_CLICKHOUSE_ALL=0 \
           -DENABLE_CLICKHOUSE_SERVER=1 \
           -DENABLE_CLICKHOUSE_CLIENT=1 \
           -DENABLE_CLICKHOUSE_LOCAL=1 \
           -DENABLE_CLICKHOUSE_BENCHMARK=1 \
           ../src
    }
    ;;
*)
    echo "Usage: $0 [d|r|a]"
    exit 1
    ;;
esac

mkdir -p "$bdir"

if [ -d build ] && [ ! -h build ]; then
    echo "A real directory named 'build' should not exist. Remove it manually then proceed again."
    exit 1
fi

ln -sfT "$bdir" build

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
