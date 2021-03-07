#!/usr/bin/env bash

HBASE_TIME_STARTUP=15
HBASE_EXPORTER_TIME_STARTUP=60
HBASE_CMD="./bin/hbase-daemon.sh --config conf start master"
HDFS_FORMAT=false
HDFS_CMD_NAMENODE="./hadoop/bin/hdfs --config hadoop/etc/hadoop namenode"
HDFS_CMD_DATANODE="./hadoop/bin/hdfs --config hadoop/etc/hadoop datanode"
HDFS_CMD_FORMAT="./hadoop/bin/hdfs --config hadoop/etc/hadoop namenode -format"

source setup.sh

setup_suite() {
    if [ "FreeBSD" = $(uname) ]; then
        export JAVA_HOME=${JAVA_HOME:-"/usr/local"}
    else
        export JAVA_HOME=${JAVA_HOME:-"/"}
    fi

    export HADOOP_PREFIX="$(pwd)/hadoop"

    # Setup HBase
    if ! ./hbase-setup.sh; then
         printf "Failed to setup HBase to run test suite\n"
         exit 1
    fi

    # Setup HDFS
    if ! ./hdfs-setup.sh; then
         printf "Failed to setup HDFS to run test suite\n"
         exit 1
    fi

    # Start hdfs
    if [ true = "$HDFS_FORMAT" ]; then
        printf "Formatting %s\n" "$1"
        r=run $HDFS_CMD_FORMAT "HDFS_FORMAT"
    fi

    run "$HDFS_CMD_NAMENODE" "HDFS Namenode"
    run "$HDFS_CMD_DATANODE" "HDFS Datanode"

    # Start HBase
    cd hbase/ || exit
    run "$HBASE_CMD" "HBASE"
    if [[ "$r" == *"Stop it first."* ]]; then
        printf "HBase is already running. Stop it manually first, then run script again"
        exit 1
    fi
    sleep $HBASE_TIME_STARTUP

    # Start exporter
    run_exporter
    printf "Waiting %ss to gather exporter values\n" ${HBASE_EXPORTER_TIME_STARTUP}
    sleep $HBASE_EXPORTER_TIME_STARTUP
}

run_exporter() {
    cd ../../ || exit
    printf "Starting hbase-exporter\n"
    ./hbase-exporter --zookeeper-server="${ZK_SERVER:-"127.0.0.1"}" \
                     --hbase-pseudo-distributed=True \
                     --hbase-table="foo" > /dev/null 2>&1 &
    PID=$!
}

test_hdfs_up() {
    assert "curl -s http://127.0.0.1:50070 > /dev/null" "HDFS: Namenode ui down"
    assert "curl -s http://127.0.0.1:8021 > /dev/null" "HDFS: IPC down"
}

test_hbase_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"16010\"}\"" "HBase: Not running"
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
    assert_not_equals "0.0" "$r" "exporter: Zookeeper has no leader"
    assert_not_equals "" "$r" "exporter: Zookeeper has no leader"
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

test_hbase_exporter_export_hdfs_datanodes_live() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hdfs_datanodes_live' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "exporter: HDFS - No data nodes"
    assert_not_equals "" "$r" "exporter: HDFS - No data nodes"
}

test_hbase_exporter_export_hdfs_datanodes_dead() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^hdfs_datanodes_dead' | cut -d " " -f2)
    assert_equals "0.0" "$r" "exporter: HDFS - Dead data nodes"
    assert_not_equals "" "$r" "exporter: HDFS - Dead data nodes"
}

teardown_suite() {
    printf "Stopping hbase-exporter (%s)\n" "$PID"
    if ! kill $PID > /dev/null 2>&1; then
        printf "Failed to send SIGTERM to %s\n" "$PID"
    fi

    printf "Stopping HBase\n"
    ./tests/hbase/bin/hbase-daemon.sh stop master
}
