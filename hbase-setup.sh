#!/usr/bin/env bash

set -ueo pipefail

HBASE_VERSION="2.4.1"
HBASE_FILE="hbase-${HBASE_VERSION}-bin.tar.gz"
HBASE_URL="https://downloads.apache.org/hbase/${HBASE_VERSION}/${HBASE_FILE}"
HBASE_FILE_CKSUM="5afb643c2391461619516624168e042b42a66e25217a3319552264c6af522e3a21a5212bfcba759b7b976794648ef13ee7b5a415f33cdb89bba43d40162aa685"
HBASE_HOST="127.0.0.1"

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

download() {
    if [ -f "$HBASE_FILE" ]; then
        CKSUM="$(sha512 -q ${HBASE_FILE})"
        if [ "$CKSUM" = "$HBASE_FILE_CKSUM" ]; then
            printf "HBase archive exists\n"
        fi
    else
        printf "Downloading ${1}\n"
        curl -LO ${1}
    fi

    printf "Extracting archive\n"
    tar xfz ${HBASE_FILE}
}

create_config() {
    printf "Writing config\n"
    cat <<EOF > $2
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
download ${HBASE_URL}
create_config "/tmp" "hbase-${HBASE_VERSION}/conf/hbase-site.xml"
