#!/usr/bin/env bash

set -ueo pipefail

HBASE_VERSION="2.4.1"
HBASE_FILE="hbase-${HBASE_VERSION}-bin.tar.gz"
HBASE_URL="https://downloads.apache.org/hbase/${HBASE_VERSION}/${HBASE_FILE}"
HBASE_FILE_CKSUM="5afb643c2391461619516624168e042b42a66e25217a3319552264c6af522e3a21a5212bfcba759b7b976794648ef13ee7b5a415f33cdb89bba43d40162aa685"
HBASE_CONFIG="hbase/conf/hbase-site.xml"
HBASE_TEST_SUITE_EXECUTABLE="hbase/bin/hbase"

declare -a DEPS=("java")

check_dependencies() {
    for i in "${DEPS[@]}"
    do
        if [[ -z $(which "${i}") ]]; then
            error "Could not find ${i}"
            exit 1
        fi
    done
}

prepare_hbase() {
    if ! [ -f "$HBASE_TEST_SUITE_EXECUTABLE" ]; then
        if [ -f "$HBASE_FILE" ]; then
            CKSUM="$(sha512 -q ${HBASE_FILE})"
            if [ "$CKSUM" = "$HBASE_FILE_CKSUM" ]; then
                printf "HBase archive exists\n"
            fi
        else
            printf "Downloading %s\n" "$1"
            curl -LO "${1}"
        fi

        printf "Extracting HBase archive\n"
        tar xfz ${HBASE_FILE}
        mv -f hbase-${HBASE_VERSION} hbase/
    fi
}

create_config() {
    printf "Writing HBase config\n"
    cat <<EOF > "$2"
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
}

check_dependencies
prepare_hbase ${HBASE_URL}
create_config "/tmp" ${HBASE_CONFIG}
