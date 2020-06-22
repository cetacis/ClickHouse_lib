#!/usr/bin/env bash

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

rm -rf build/dbms/programs/clickhouse
ninja -C build -v
