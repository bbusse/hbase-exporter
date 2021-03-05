#!/usr/bin/env bash

HBASE_HOST="127.0.0.1"
HBASE_PORT=16020
ZK_HOST="$HBASE_HOST"
ZK_PORT=2181
HBASE_TIME_STARTUP=15
HBASE_EXPORTER_TIME_STARTUP=60
HBASE_VERSION="2.4.1"

setup_suite() {
    export JAVA_HOME=${JAVA_HOME:-"/usr/local"}

    # Setup HBase
    ./hbase-setup.sh

    # Run HBase
    cd hbase
    printf "Starting HBase in pseudo-distributed mode\n"
    ./bin/hbase-daemon.sh --config conf start master
    sleep ${HBASE_TIME_STARTUP}

    # Run exporter
    cd ../../
    printf "Starting hbase-exporter\n"
    ./hbase-exporter --zookeeper-server=${ZK_SERVER:-"127.0.0.1"} \
                     --hbase-pseudo-distributed=True \
                     --hbase-table="foo" 2>&1 > /dev/null &
    PID=$!
}

test_hbase_running() {
    nc -n -w1 ${1:-"127.0.0.1"} ${2:-"16200"}
}

test_hbase_zk_running() {
    r=`nc -n -w1 ${1:-"127.0.0.1"} ${2:-"2181"} <<END
"ruok"
END
`
    printf "$r"
}

test_hbase_exporter_up() {
    nc -nu -w1 ${1:-"127.0.0.1"} ${2:-"9010"} 2>&1 > /dev/null &
    curl -s http://127.0.0.1:9010 > /dev/null
}

test_hbase_exporter_export_zk_live() {
    sleep $HBASE_EXPORTER_TIME_STARTUP
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_num_live' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "Zookeeper not live"
}

test_hbase_exporter_export_hbase_up() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hbase_up' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "HBase down"
}

test_hbase_exporter_export_zk_connection_count() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_num_connections' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "Zookeeper has no connections"
}

teardown_suite() {
    kill $PID
    ./tests/hbase/bin/hbase-daemon.sh stop master
}
