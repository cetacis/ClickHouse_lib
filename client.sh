#!/usr/bin/env bash

"$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse client "$@"
