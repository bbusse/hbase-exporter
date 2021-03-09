#!/usr/bin/env bash

set -ueo pipefail

HBASE_VERSION="0.96.1.1"
HBASE_FILE="hbase-${HBASE_VERSION}-hadoop2-bin.tar.gz"
HBASE_DIR="hbase-${HBASE_VERSION}-hadoop2"
#HBASE_URL="https://downloads.apache.org/hbase/${HBASE_VERSION}/${HBASE_FILE}"
HBASE_URL="https://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/${HBASE_FILE}"
HBASE_FILE_CKSUM="1625453f839f7d8c86078a131af9731f6df28c59e58870db84913dcbc640d430253134a825de7cec247ea1f0cf232435765e00844ee2e4faf31aeb356955c478"
HBASE_PATH="/tmp"
HBASE_CONFIG_TEMPLATE="${HBASE_PATH}/hbase/conf/hbase-site.xml.j2"

SCRIPT_PATH=$(dirname "$0")
source $SCRIPT_PATH/../../../setup.sh

create_hbase_config_template() {
    read -r -d '' CONFIG <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file:///{{ hbase_rootdir }}/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>{{ hbase_datadir }}/zookeeper</value>
  </property>
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

HBASE_CONFIG=$(create_hbase_config_template)
write_file ${HBASE_CONFIG_TEMPLATE} "${HBASE_CONFIG}"
