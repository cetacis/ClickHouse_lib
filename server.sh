#!/usr/bin/env bash

export LD_BIND_NOW=1

clickhouse="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse

case "$(basename "$0")" in
s)
    $clickhouse server --config etc/config.xml "$@"
    ;;
s5)
    $clickhouse server --config etc/config-s5.xml "$@"
    ;;
*)
    echo "There is no server called $0 yet."
    exit 1
    ;;
esac
