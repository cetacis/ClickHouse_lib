#!/usr/bin/env bash

export LD_BIND_NOW=1
base=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
clickhouse="$base"/build-dev/dbms/programs/clickhouse
case "$(basename "$0")" in
    cq)
        $clickhouse client --config "$base"/etc/config-client.xml -tmn --query "$*"
        ;;
    cqo)
        $clickhouse client --port 9001 --config "$base"/etc/config-client.xml -tmn --query "$*"
        ;;
    c)
        $clickhouse client --case_insensitive_suggestion -n "$@"
        ;;
    co)
        $clickhouse client --case_insensitive_suggestion --port 9001 -n "$@"
        ;;
esac
