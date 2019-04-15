# hbase-exporter

## An HBase Prometheus Exporter

Relays JMX metrics for consumption by Prometheus

The exporter parses the (Hortonworks) Hadoop config and uses (Hortonworks)
Hadoop internal tooling to determine e.g. the currently active master
so that it can run in different environments without requiring any configuration

Those tools are not yet included when building the app as a container!

Since some important metrics are missing or empty in JMX, we additionally parse the HBase Master UI
for e.g. 'Stale regions in transition'

The hbase hbck log is parsed to check for inconsistencies in HBase.
The log is created independently from the exporter with the help of
a systemd-timer unit and a systemd-hbck-service unit

Unfortunately querying the active namenode requires superuser privileges

For python module requirements see requirements.txt
or execute the commands outlined below

```sh
$ sudo dnf/yum install python36
```

```sh
# As the user executing the exporter:
$ pip3[.6] install --user beautifulsoup4 flatten_json kazoo prometheus_client requests
```
