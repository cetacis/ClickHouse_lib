#!/usr/bin/env bash

build/dbms/programs/clickhouse server --config etc/config.xml "$@"
