#!/usr/bin/env bash
set -euo pipefail

sudo ./runner --binary $HOME/git/ClickHouse/build/programs/clickhouse  --bridge-binary $HOME/git/ClickHouse/build/programs/clickhouse-odbc-bridge --base-configs-dir $HOME/git/ClickHouse/src/programs/server 'test_jbod_balancer -ss --verbose'
