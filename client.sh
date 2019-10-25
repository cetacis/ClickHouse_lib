#!/usr/bin/env bash

case "$(basename "$0")" in
    cq)
        "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse client -mn <<< "$*"
        ;;
    c)
        "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse client -n "$@"
        ;;
esac
