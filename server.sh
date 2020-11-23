#!/usr/bin/env bash

set -e
export LD_BIND_NOW=1

# export LIBUNWIND_PRINT_DWARF=1
# export LIBUNWIND_PRINT_UNWINDING=1
# export LIBUNWIND_PRINT_APIS=1
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export LIBHDFS3_CONF=etc/hdfs-client.xml

clickhouse_server=build/programs/clickhouse-server
config_path=etc

case "$(basename "$0")" in
s)
    # numactl --membind=0 taskset -c 10 $clickhouse server --config "$config_path"/config-dev.xml "$@"
    /tmp/gentoo/lib64/ld-linux-x86-64.so.2 $clickhouse_server --config "$config_path"/config-dev.xml "$@"
    ;;
sd)
    # numactl --membind=0 taskset -c 10 $clickhouse_server --config "$config_path"/config-dev.xml "$@"
    tmuxgdb $clickhouse_server --config "$config_path"/config-dev.xml "$@"
    ;;
s2)
    /tmp/gentoo/lib64/ld-linux-x86-64.so.2 $clickhouse_server --config "$config_path"/config-dev2.xml "$@"
    ;;
s5)
    $clickhouse_server --config "$config_path"/config-s5.xml "$@"
    ;;
so)
    # numactl --membind=0 taskset -c 16 "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build-ori/programs/clickhouse server --config "$config_path"/config-ori.xml "$@"
    build-ori/programs/clickhouse server --config "$config_path"/config-ori.xml "$@"
    ;;
soc)
    build-ori-clang/programs/clickhouse server --config "$config_path"/config-ori.xml "$@"
    ;;
so2)
    build-ori/programs/clickhouse server --config "$config_path"/config-dev.xml "$@"
    ;;
*)
    echo "There is no server called $0 yet."
    exit 1
    ;;
esac
