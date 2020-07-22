#!/usr/bin/env bash

until netstat -plnt 2>/dev/null | rg -q 19000 ; do sleep 0.2; done
export LD_BIND_NOW=1
base=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
clickhouse="$base"/build/programs/clickhouse
case "$(basename "$0")" in
    cq)
        $clickhouse client --port 19000 --config "$base"/etc/config-client.xml -tmn --query "$*"
        ;;
    cqo)
        $clickhouse client --port 9001 --config "$base"/etc/config-client.xml -tmn --query "$*"
        ;;
    c)
        $clickhouse client --port 19000 -n "$@"
        ;;
    co)
        $clickhouse client --port 9001 -n "$@"
        ;;
    ct)
        $clickhouse client --host dataarch-ls-c1.idczw.hb1.kwaidc.com --port 9100 -n "$@"
        ;;
esac
