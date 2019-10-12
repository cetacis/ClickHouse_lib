#!/usr/bin/env bash

case "$(basename "$0")" in
ub)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server -e SKIP_TESTS_OPTION="--skip 00281 capnproto avx2 query_profiler" -e ADDITIONAL_OPTIONS="--hung-check" yandex/clickhouse-stateless-test
    ;;
rel)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server -e SKIP_TESTS_OPTION="--skip avx2" -e ADDITIONAL_OPTIONS="--hung-check" yandex/clickhouse-stateless-test
    ;;
uni)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/ClickHouse/build/dbms/unit_tests_dbms:/unit_tests_dbms --volume=/tmp/test_output:/test_output yandex/clickhouse-unit-test
    ;;
pf)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server --volume=/data/clickhouse-testdata:/var/lib/clickhouse -e DOWNLOAD_DATASETS=0 -e TESTS_TO_RUN='--recursive --input-files /usr/share/clickhouse-test/performance/' yandex/clickhouse-performance-test
    ;;
pf1)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/clickhouse-debs:/package_folder --volume=/tmp/test_output1:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server --volume=/data/clickhouse-testdata:/var/lib/clickhouse -e DOWNLOAD_DATASETS=0 -e TESTS_TO_RUN='--input-files /usr/share/clickhouse-test/performance/website.xml --query-indexes 67 68 69 70' yandex/clickhouse-performance-test
    ;;
pf2)
    docker run --rm --ulimit nofile=1000000:1000000 --volume=/data/chorigin-debs:/package_folder --volume=/tmp/test_output2:/test_output --volume=/tmp/server_log:/var/log/clickhouse-server --volume=/data/clickhouse-testdata:/var/lib/clickhouse -e DOWNLOAD_DATASETS=0 -e TESTS_TO_RUN='--input-files /usr/share/clickhouse-test/performance/website.xml --query-indexes 67 68 69 70' yandex/clickhouse-performance-test
    ;;
*)
    echo "There is no test for this variant yet."
    exit 1
    ;;
esac
