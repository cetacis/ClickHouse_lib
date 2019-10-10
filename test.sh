#!/usr/bin/env bash

case "$(basename "$0")" in
ub)
    docker run --rm --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server -e SKIP_TESTS_OPTION="--skip 00281 capnproto avx2 query_profiler" -e ADDITIONAL_OPTIONS="--hung-check" yandex/clickhouse-stateless-test
    ;;
rel)
    docker run --rm --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server -e SKIP_TESTS_OPTION="--skip avx2" -e ADDITIONAL_OPTIONS="--hung-check" yandex/clickhouse-stateless-test
    ;;
*)
    echo "There is no test for this variant yet."
    exit 1
    ;;
esac
