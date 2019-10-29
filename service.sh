#!/usr/bin/env bash

dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
case "$(basename "$0")" in
zookeeper)
    docker-compose -f "$dir/src/dbms/tests/integration/helpers/docker_compose_zookeeper.yml" up
    ;;
kafka)
    docker-compose -f "$dir/src/dbms/tests/integration/helpers/docker_compose_kafka.yml" up
    ;;
*)
    echo "There is no service called $0 yet."
    exit 1
    ;;
esac
