#!/usr/bin/env bash

set -ueo pipefail

HBASE_VERSION="0.96.1.1"
HBASE_FILE="hbase-${HBASE_VERSION}-hadoop2-bin.tar.gz"
HBASE_DIR="hbase-${HBASE_VERSION}-hadoop2"
#HBASE_URL="https://downloads.apache.org/hbase/${HBASE_VERSION}/${HBASE_FILE}"
HBASE_URL="https://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/${HBASE_FILE}"
HBASE_FILE_CKSUM="1625453f839f7d8c86078a131af9731f6df28c59e58870db84913dcbc640d430253134a825de7cec247ea1f0cf232435765e00844ee2e4faf31aeb356955c478"
HBASE_CONFIG_FILE="hbase/conf/hbase-site.xml"
HBASE_TEST_SUITE_EXECUTABLE="hbase/bin/hbase"

declare -a DEPS=("java")

source setup.sh

create_hbase_config() {
    read -r -d '' CONFIG <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file:///${1}/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>${1}/zookeeper</value>
  </property>
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

prepare_hbase() {
    if ! [ -f "$HBASE_TEST_SUITE_EXECUTABLE" ]; then
        if [ -f "$HBASE_FILE" ]; then
            printf "HBase archive exists\n"
            if compare_checksum $HBASE_FILE $HBASE_FILE_CKSUM; then
                extract_archive $HBASE_FILE $HBASE_VERSION
                mv -f "${HBASE_DIR}" hbase
                return
            else
                printf "HBase archive has wrong checksum (%s)\n" "$1"
                printf "Execute script again to redownload file\n"
                exit 1
            fi
        fi

        printf "Downloading %s\n" "$1"
        curl -LO "${1}"

        if compare_checksum $HBASE_FILE $HBASE_FILE_CKSUM; then
            extract_archive $HBASE_FILE $HBASE_VERSION
            mv -f ${HBASE_DIR} hbase
        fi
    fi
}

check_dependencies
prepare_hbase ${HBASE_URL}
HBASE_CONFIG=$(create_hbase_config "/tmp")
write_file ${HBASE_CONFIG_FILE} "${HBASE_CONFIG}"
