#!/usr/bin/env bash

export LD_BIND_NOW=1
clickhouse="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse
case "$(basename "$0")" in
    cq)
        $clickhouse client -mn <<< "$*"
        ;;
    c)
        $clickhouse client -n "$@"
        ;;
esac
