#!/usr/bin/env bash

set -ueo pipefail

HADOOP_VERSION="2.10.1"
HADOOP_FILE="hadoop-$HADOOP_VERSION.tar.gz"
HADOOP_URL="https://artfiles.org/apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
HADOOP_FILE_CKSUM="2460e02cd1f80dfed7a8981bbc934c095c0a341435118bec781fd835ec2ebdc5543a03d92d24f2ddeebdfe1c2c460065ba1d394ed9a73cbb2020b40a8d8b5e07"
HDFS_CONFIG_FILE="hadoop/etc/hadoop/hdfs-site.xml"
HDFS_CONFIG_FILE_CORE="hadoop/etc/hadoop/core-site.xml"
HDFS_CONFIG_FILE_MAPRED="hadoop/etc/hadoop/mapred-site.xml"
HDFS_CONFIG_DATANODES="localhost"
HDFS_TEST_SUITE_EXECUTABLE="hadoop/bin/hdfs"

source setup.sh

declare -a DEPS=("java")

create_hdfs_core_config() {
    #printf "Writing HDFS core-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>fs.defaultFS</name>
      <value>hdfs://$2</value>
   </property>
</configuration>
EOF
    echo "$CONFIG"
}

create_hdfs_mapred_config() {
    #printf "Writing HDFS mapred-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://$1</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

create_hdfs_config() {
    #printf "Writing HDFS hdfs-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>dfs.nameservices</name>
    <value>$2</value>
  </property>
  <property>
    <name>dfs.ha.namenodes.$2</name>
    <value>nn1,nn2</value>
  </property>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://$2</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.$2.nn1</name>
    <value>master-1:8020</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.$2.nn2</name>
    <value>master-2:8020</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.$2.nn1</name>
     <value>master-1:50070</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.$2.nn2</name>
     <value>master-2:50070</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/tmp/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/tmp/hdfs/datanode</value>
  </property>
  <property>
    <name>dfs.namenode.shared.edits.dir</name>
    <value>file:///tmp/hadoop</value>
  </property>
  <property>
    <name>ha.zookeeper.quorum</name>
    <value>127.0.0.1:2181</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

prepare_hadoop() {
    if ! [ -f "$HDFS_TEST_SUITE_EXECUTABLE" ]; then
        printf "Setting up Hadoop\n"
        if [ -f "$HADOOP_FILE" ]; then
            printf "Hadoop archive exists\n"
            if compare_checksum $HADOOP_FILE $HADOOP_FILE_CKSUM; then
                extract_archive "$HADOOP_FILE" "$HADOOP_VERSION"
                mv -f hadoop-$HADOOP_VERSION hadoop/
                return
            else
                printf "Hadoop archive has wrong checksum (%s)\n" "$1"
                printf "Execute script again to redownload file\n"
                exit 1
            fi
        fi

        printf "Downloading %s\n" "$1"
        curl -LO "${1}"
        if compare_checksum $HADOOP_FILE $HADOOP_FILE_CKSUM; then
            extract_archive "$HADOOP_FILE" "$HADOOP_VERSION"
            mv -f hadoop-$HADOOP_VERSION hadoop/
        fi
    fi
}

check_dependencies
prepare_hadoop ${HADOOP_URL}
HDFS_CONFIG=$(create_hdfs_config "127.0.0.1:8020" "test-cluster")
HDFS_CONFIG_CORE=$(create_hdfs_core_config "127.0.0.1:8020" "test-cluster")
HDFS_CONFIG_MAPRED=$(create_hdfs_mapred_config "127.0.0.1:8021")
write_file ${HDFS_CONFIG_FILE} "${HDFS_CONFIG}"
write_file ${HDFS_CONFIG_FILE_CORE} "${HDFS_CONFIG_CORE}"
write_file ${HDFS_CONFIG_FILE_MAPRED} "${HDFS_CONFIG_MAPRED}"
write_file ${HDFS_CONFIG_DATANODES} "localhost"
