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


### Build/Install Dependencies
For python module requirements see requirements.txt
```sh
$ sudo dnf/pkg install python3
```

As the user executing the exporter (e.g. hdfs):
```sh
$ sudo su - hdfs
$ pip3 install --user -r requirements.txt
```

The protobuf compiler is necessary to build the required bindings for Python

Install the protobuf compiler
```
# FreeBSD
$ sudo pkg install protobuf-c

# Fedora / RHEL / CentOS
$ sudo dnf install protobuf-c protobuf-devel

# Debian / Ubuntu
$ sudo apt install protobuf-compiler libprotobuf-dev
```

#### Build the protobuf bindings
To generate the necessary HBase Python Protobuf bindings, run make
```
$ make
```

#### Install the protobuf bindings
```
$ cp -R hbase-protobuf-python /usr/local/lib
```

### Run
The exporter needs to know about the ZooKeeper servers to connect to, so start
the exporter with e.g.
```
$ PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION="python" \
  hbase-exporter --zookeeper-server-address=zk-1.acme.internal \
                 --zookeeper-server-address=zk-2.acme.internal \
                 --zookeeper-server-address=zk-3.acme.internal \
                 --export-refresh-rate=60 \
                 --hbck-refresh-rate=1200
```
or use the systemd-unit and configure the zookeeper servers and refresh rates via the supplied environment file

Run 'hbase-exporter --help' for all arguments
```
$ hbase-exporter --help
usage: hbase-exporter [-h] [--hbase-master HBASE_MASTER]
                      [--hbase-pseudo-distributed HBASE_PSEUDO_DISTRIBUTED]
                      --hbase-table HBASE_TABLE
                      [--hdfs-namenode HDFS_NAMENODE]
                      --zookeeper-server-address ZK_SERVER
                      [--zookeeper-use-tls ZK_USE_TLS]
                      [--exporter-port PROM_HTTP_PORT]
                      [--export-refresh-rate PROM_EXPORT_INTERVAL_S]
                      [--hbck-refresh-rate HBASE_HBCK_INTERVAL_S]
                      [--relay-jmx RELAY_JMX] [--logfile LOGFILE]
                      [--loglevel LOGLEVEL]

If an arg is specified in more than one place, then commandline values
override environment variables which override defaults.

optional arguments:
  -h, --help            show this help message and exit
  --hbase-master HBASE_MASTER
                        HBase master address, can be specified multiple times
                        [env var: HBASE_MASTER]
  --hbase-pseudo-distributed HBASE_PSEUDO_DISTRIBUTED
                        Indicated whether HBase is run in pdeudo-distributed
                        mode [env var: HBASE_PSEUDO_DISTRIBUTED]
  --hbase-table HBASE_TABLE
                        The HBase table for the write test [env var:
                        HBASE_TABLE]
  --hdfs-namenode HDFS_NAMENODE
                        HDFS namenode address, can be specified multiple times
                        [env var: HDFS_NAMENODE]
  --zookeeper-server-address ZK_SERVER
                        ZooKeeper server address, can be specified multiple
                        times [env var: ZK_SERVER]
  --zookeeper-use-tls ZK_USE_TLS
                        Use TLS when connecting to ZooKeeper [env var:
                        ZK_USE_TLS]
  --exporter-port PROM_HTTP_PORT
                        Listen port for Prometheus export [env var:
                        PROM_HTTP_PORT]
  --export-refresh-rate PROM_EXPORT_INTERVAL_S
                        Time between metrics are gathered in seconds [env var:
                        PROM_EXPORT_INTERVAL_S]
  --hbck-refresh-rate HBASE_HBCK_INTERVAL_S
                        Minimum time between two consecutive hbck runs in
                        seconds [env var: HBASE_HBCK_INTERVAL_S]
  --relay-jmx RELAY_JMX
                        Relay complete JMX data [env var: RELAY_JMX]
```

### Deploy
Ansible can be used to build and deploy the hbase-exporter
```
$ ansible-playbook -v -i inventory/env.yml deploy-hbase-exporter.yml -l host
````

### Test
To run the tests
```
$ make test
```

### Debug
To see the log
```
$ sudo journalctl -afn100 -uhbase-exporter

