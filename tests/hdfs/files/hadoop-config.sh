#!/usr/bin/env bash

set -ueo pipefail

HADOOP_VERSION="2.10.1"
HADOOP_FILE="hadoop-$HADOOP_VERSION.tar.gz"
HADOOP_URL="https://artfiles.org/apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
HADOOP_FILE_CKSUM="2460e02cd1f80dfed7a8981bbc934c095c0a341435118bec781fd835ec2ebdc5543a03d92d24f2ddeebdfe1c2c460065ba1d394ed9a73cbb2020b40a8d8b5e07"
HDFS_CONFIG_TEMPLATE="hadoop/etc/hadoop/hdfs-site.xml.j2"
HDFS_CONFIG_TEMPLATE_CORE="hadoop/etc/hadoop/core-site.xml.j2"
HDFS_CONFIG_TEMPLATE_MAPRED="hadoop/etc/hadoop/mapred-site.xml.j2"
HDFS_CONFIG_DATANODES="localhost"
HDFS_TEST_SUITE_EXECUTABLE="hadoop/bin/hdfs"

SCRIPT_PATH=$(dirname "$0")
source $SCRIPT_PATH/../../setup.sh

create_hdfs_core_config_template() {
    #printf "Writing HDFS core-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://{{ cluster_id }}</value>
  </property>
  <property>
    <name>dfs.journalnode.edits.dir</name>
    <value>/.tmp/hadoop</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

create_hdfs_mapred_config_template() {
    #printf "Writing HDFS mapred-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://{{ cluster_ha_id }}</value>
  </property>
</configuration>
EOF
    echo "$CONFIG"
}

create_hdfs_config_template() {
    #printf "Writing HDFS hdfs-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>dfs.nameservices</name>
    <value>{{ cluster_id }}</value>
  </property>
  <property>
    <name>dfs.ha.namenodes.{{ cluster_id }}</name>
    <value>nn1,nn2</value>
  </property>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://{{ cluster_id }}</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.{{ cluster_id }}.nn1</name>
    <value>{{ namenode_1 }}:8020</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.{{ cluster_id }}.nn2</name>
    <value>{{ namenode_2 }}:8020</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.{{ cluster_id }}.nn1</name>
     <value>{{ namenode_1 }}:50070</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.{{ cluster_id }}.nn2</name>
     <value>{{ namenode_2}}:50070</value>
  </property>
  <property>
    <name>dfs.namenode.http-address.{{ cluster_id }}.nn1</name>
    <value>{{ namenode_1 }}:9870</value>
  </property>
  <property>
    <name>dfs.namenode.http-address.{{ cluster_id }}.nn2</name>
    <value>{{ namenode_2 }}:9870</value>
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

HDFS_CONFIG=$(create_hdfs_config_template)
HDFS_CONFIG_CORE=$(create_hdfs_core_config_template)
HDFS_CONFIG_MAPRED=$(create_hdfs_mapred_config_template)
write_file ${HDFS_CONFIG_TEMPLATE} "${HDFS_CONFIG}"
write_file ${HDFS_CONFIG_TEMPLATE_CORE} "${HDFS_CONFIG_CORE}"
write_file ${HDFS_CONFIG_TEMPLATE_MAPRED} "${HDFS_CONFIG_MAPRED}"
write_file ${HDFS_CONFIG_DATANODES} "localhost"
