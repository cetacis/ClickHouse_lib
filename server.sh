#!/usr/bin/env bash

set -e
export LD_BIND_NOW=1

# export LIBUNWIND_PRINT_DWARF=1
# export LIBUNWIND_PRINT_UNWINDING=1
# export LIBUNWIND_PRINT_APIS=1
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

clickhouse=build/programs/clickhouse
config_path=etc

case "$(basename "$0")" in
s)
    # numactl --membind=0 taskset -c 10 $clickhouse server --config "$config_path"/config-dev.xml "$@"
    $clickhouse server --config "$config_path"/config-dev.xml "$@"
    ;;
s2)
    $clickhouse server --config "$config_path"/config-ori.xml "$@"
    ;;
s5)
    $clickhouse server --config "$config_path"/config-s5.xml "$@"
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
