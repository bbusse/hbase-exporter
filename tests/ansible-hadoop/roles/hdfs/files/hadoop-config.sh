#!/usr/bin/env bash

set -ueo pipefail

HDFS_CONFIG_TEMPLATE="/tmp/hadoop/etc/hadoop/hdfs-site.xml.j2"
HDFS_CONFIG_TEMPLATE_CORE="/tmp/hadoop/etc/hadoop/core-site.xml.j2"
HDFS_CONFIG_TEMPLATE_MAPRED="/tmp/hadoop/etc/hadoop/mapred-site.xml.j2"

SCRIPT_PATH=$(dirname "$0")
source setup.sh

create_hdfs_core_config_template() {
    #printf "Writing HDFS core-site.xml config\n"
    read -r -d '' CONFIG <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://{{ hdfs_cluster_id }}</value>
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
    <value>{{ hdfs_cluster_id }}</value>
  </property>
  <property>
    <name>dfs.ha.namenodes.{{ hdfs_cluster_id }}</name>
    <value>nn1,nn2</value>
  </property>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://{{ hdfs_cluster_id }}</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.{{ hdfs_cluster_id }}.nn1</name>
    <value>{{ namenode_1 }}:8020</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-address.{{ hdfs_cluster_id }}.nn2</name>
    <value>{{ namenode_2 }}:8020</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.{{ hdfs_cluster_id }}.nn1</name>
     <value>{{ namenode_1 }}:50070</value>
  </property>
  <property>
     <name>dfs.namenode.http-address.{{ hdfs_cluster_id }}.nn2</name>
     <value>{{ namenode_2}}:50070</value>
  </property>
  <property>
    <name>dfs.namenode.http-address.{{ hdfs_cluster_id }}.nn1</name>
    <value>{{ namenode_1 }}:9870</value>
  </property>
  <property>
    <name>dfs.namenode.http-address.{{ hdfs_cluster_id }}.nn2</name>
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
