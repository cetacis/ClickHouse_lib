#!/usr/bin/env bash

"$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/build/dbms/programs/clickhouse server --config etc/config.xml "$@"
