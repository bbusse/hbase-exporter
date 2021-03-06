#!/usr/bin/env bash

set -ueo pipefail

HBASE_VERSION="0.96.1.1"
HBASE_FILE="hbase-${HBASE_VERSION}-hadoop2-bin.tar.gz"
#HBASE_URL="https://downloads.apache.org/hbase/${HBASE_VERSION}/${HBASE_FILE}"
HBASE_URL="https://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/${HBASE_FILE}"
HBASE_FILE_CKSUM="5afb643c2391461619516624168e042b42a66e25217a3319552264c6af522e3a21a5212bfcba759b7b976794648ef13ee7b5a415f33cdb89bba43d40162aa685"
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
                mv -f hbase-"${VERSION}" hbase/
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
            mv -f hbase-${HBASE_VERSION} hbase/
        fi
    fi
}

check_dependencies
prepare_hbase ${HBASE_URL}
HBASE_CONFIG=$(create_hbase_config "/tmp")
write_file ${HBASE_CONFIG_FILE} "${HBASE_CONFIG}"
