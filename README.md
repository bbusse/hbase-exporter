# hbase-exporter

## An HBase Prometheus Exporter

Collects metrics and relays JMX metrics for consumption by Prometheus

Since some important metrics are missing or empty in JMX, we additionally parse the HBase Master UI
for e.g. 'Stale regions in transition'

The output of the 'hbase hbck' command is parsed to check for inconsistencies in HBase

Marking Hbase unhealthy requires one of the following conditions to be true
- There is at least one stale region in transition
- The 'hbase hbck' command shows HBase inconsistencies
- A write to the predefined table does not succeed
- A ZooKeeper leader can not be determined


### Dependencies
For python module requirements see requirements.txt
```sh
$ sudo dnf/pkg install python36
```

As the user executing the exporter:
```sh
$ pip3[.6] install --user -r requirements.txt
```

The protobuf compiler is necessary to build the required bindings for Python

Install the protobuf compiler
```
$ sudo dnf/pkg install protobuf-c protobuf-devel
```

### Build
To generate the necessary HBase Python Protobuf bindings, run make
```
$ make
```

### Run
The exporter needs to know about the ZooKeeper servers to connect to, so start
the exporter with e.g.
```
$ hbase-exporter --zookeeper-server-address=zk-1.acme.internal
                 --zookeeper-server-address=zk-2.acme.internal
                 --zookeeper-server-address=zk-3.acme.internal
                 --export-refresh-rate=60
                 --hbck-refresh-rate=1200
```

Run 'hbase-exporter --help' for all arguments
```
$ hbase-exporter --help
usage: hbase-exporter [-h] [--hbase-master HBASE_MASTER]
                      [--hdfs-namenode HDFS_NAMENODE]
                      --zookeeper-server-address ZK_SERVER
                      [--zookeeper-use-tls ZK_USE_TLS]
                      [--exporter-port PROM_HTTP_PORT]
                      [--export-refresh-rate PROM_EXPORT_INTERVAL_S]
                      [--hbck-refresh-rate HBASE_HBCK_INTERVAL_S]
                      [--relay-jmx RELAY_JMX] [--logfile LOGFILE]
                      [--loglevel LOGLEVEL]

optional arguments:
  -h, --help            show this help message and exit
  --hbase-master HBASE_MASTER
                        HBase master address, can be specified multiple times
  --hdfs-namenode HDFS_NAMENODE
                        HDFS namenode address, can be specified multiple times
  --zookeeper-server-address ZK_SERVER
                        ZooKeeper server address, can be specified multiple
                        times
  --zookeeper-use-tls ZK_USE_TLS
                        Use TLS when connecting to ZooKeeper
  --exporter-port PROM_HTTP_PORT
                        Listen port for Prometheus export
  --export-refresh-rate PROM_EXPORT_INTERVAL_S
                        Time between metrics are gathered in seconds
  --hbck-refresh-rate HBASE_HBCK_INTERVAL_S
                        Minimum time between two consecutive hbck runs in
                        seconds
  --relay-jmx RELAY_JMX
                        Relay complete JMX data
  --logfile LOGFILE     Path to optional logfile
  --loglevel LOGLEVEL   Loglevel, default: INFO
```

### Deploy
Ansible can be used to build and deploy the hbase-exporter
```
$ ansible-playbook -v -i inventory/env.yml deploy-hbase-exporter.yml -l host
````

### Debug
To see the log
```
$ sudo journalctl -afn100 -uhbase-exporter
```

## Issues
Import paths do not work in generated protobufs when used from a subdir<br>
https://github.com/protocolbuffers/protobuf/issues/1491<br>
The solution used here is mentioned in the comments:<br>
https://github.com/protocolbuffers/protobuf/issues/1491#issuecomment-547504972<br>
Unfortunately querying the active namenode requires superuser privileges
