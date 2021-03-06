#!/usr/bin/env bash

HBASE_TIME_STARTUP=15
HBASE_EXPORTER_TIME_STARTUP=60

setup_suite() {
    export JAVA_HOME=${JAVA_HOME:-"/usr/local"}

    # Setup HBase
    ./hbase-setup.sh

    # Run HBase
    cd hbase || exit
    printf "Starting HBase in pseudo-distributed mode\n"
    ./bin/hbase-daemon.sh --config conf start master
    sleep $HBASE_TIME_STARTUP

    # Run exporter
    cd ../../ || exit
    printf "Starting hbase-exporter\n"
    ./hbase-exporter --zookeeper-server="${ZK_SERVER:-"127.0.0.1"}" \
                     --hbase-pseudo-distributed=True \
                     --hbase-table="foo" > /dev/null 2>&1 &
    PID=$!
    printf "Waiting %ss to gather exporter values\n" ${HBASE_EXPORTER_TIME_STARTUP}
    sleep $HBASE_EXPORTER_TIME_STARTUP
}

test_hbase_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"16010\"}\""
}

test_hbase_zk_running() {
    r=$(echo ruok | nc -n -w1 "${1:-"127.0.0.1"}" "${2:-"2181"}")
    assert_equals "imok" "$r" "Zookeeper: Unhealthy"
}

test_hbase_exporter_up() {
    assert "curl -s http://127.0.0.1:9010 > /dev/null" "exporter: Could not GET export via Curl"
}

test_hbase_exporter_export_zk_live() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_num_live' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporter: Zookeeper not live"
    assert_not_equals "" "$r" "exporter: Zookeeper not live"
}

test_hbase_exporter_export_hbase_up() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hbase_up' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporter: HBase down"
    assert_not_equals "" "$r" "exporter: HBase down"
}

test_hbase_exporter_export_zk_connection_count() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_num_connections' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporter: Zookeeper has no connections"
    assert_not_equals "" "$r" "exporter: Zookeeper has no connections"
}

test_hbase_exporter_export_zk_has_leader() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_has_leader' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporer: Zookeeper has no leader"
    assert_not_equals "" "$r" "exporer: Zookeeper has no leader"
}

test_hbase_exporter_export_regionserver_live() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hbase_regionservers_live' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporter: HBase - No regionservers"
    assert_not_equals "" "$r" "exporter: HBase - No regionservers"
}

test_hbase_exporter_export_regionserver_dead() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hbase_regionservers_dead' | cut -d " " -f2)
    assert_equals "0.0" "$r" "exporter: HBase - Dead regionservers"
    assert_not_equals "" "$r" "exporter: HBase - Dead regionservers"
}

teardown_suite() {
    printf "Stopping hbase-exporter (%s)\n" "$PID"
    kill $PID
    ./tests/hbase/bin/hbase-daemon.sh stop master
}
