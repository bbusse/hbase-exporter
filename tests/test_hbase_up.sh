#!/usr/bin/env bash

HBASE_HOST="127.0.0.1"
HBASE_PORT=16200
ZK_HOST=$HBASE_HOST
ZK_PORT=2181
HBASE_TIME_STARTUP=8
HBASE_VERSION="2.4.1"

run_hbase() {
    cd "../hbase-${HBASE_VERSION}"
    ./bin/hbase-daemon.sh --config conf start $1
    sleep ${HBASE_TIME_STARTUP}
}

test_hbase_running() {
    nc -vnu -w1 $1 $2
}

test_hbase_zk_running() {
    nc -vnu -w1 $1 $2 <<END
"ruok"
END
}

export JAVA_HOME=${JAVA_HOME:-"/usr/local"}
run_hbase "master"
test_hbase_running ${HBASE_HOST} ${HBASE_PORT}
test_hbase_zk_running ${ZK_HOST} ${ZK_PORT}
