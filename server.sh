#!/usr/bin/env bash

export LD_BIND_NOW=1

clickhouse="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse
config_path="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/etc

case "$(basename "$0")" in
s)
    $clickhouse server --config "$config_path"/config.xml "$@"
    ;;
s5)
    $clickhouse server --config "$config_path"/config-s5.xml "$@"
    ;;
so)
    "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build-origin/dbms/programs/clickhouse server --config "$config_path"/config-origin.xml "$@"
    ;;
so2)
    "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build-origin/dbms/programs/clickhouse server --config "$config_path"/config.xml "$@"
    ;;
*)
    echo "There is no server called $0 yet."
    exit 1
    ;;
esac
