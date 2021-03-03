#!/usr/bin/env bash

setup() {
    cd ../
    ./hbase-exporter --zookeeper-server ${ZK_SERVER:-"127.0.0.1:2181"} 2>&1 > /dev/null &
    PID=$!
    sleep 5
}

test_hbase_exporter_up() {
    nc -znu -w1 ${1:-"127.0.0.1"} ${2:-"9010"}
    curl -s http://127.0.0.1:9010
}

test_hbase_exporter_zk_connection() {
    r=$(curl -s http://127.0.0.1:9010 | grep '^zookeeper_num_live' | cut -d " " -f2)
    assert_not_equals "0.0" "$r" "Zookeeper not live"
}

teardown() {
    kill "$PID"
}
