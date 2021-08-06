objcopy --only-keep-debug build/programs/clickhouse ../clickhouse-sre/clickhouse.debug && strip --strip-debug --strip-unneeded build/programs/clickhouse -o ../clickhouse-sre/clickhouse
