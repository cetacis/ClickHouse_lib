#!/usr/bin/env bash

export LD_BIND_NOW=1
base=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
clickhouse="$base"/build-ori/dbms/programs/clickhouse
clickhouse_origin="$base"/build-ori/dbms/programs/clickhouse
case "$(basename "$0")" in
    cq)
        $clickhouse client --config "$base"/etc/config-client.xml -tmn --query "$*"
        ;;
    c)
        $clickhouse_origin client -n "$@"
        ;;
    co)
        $clickhouse_origin client --port 9001 -n "$@"
        ;;
esac
