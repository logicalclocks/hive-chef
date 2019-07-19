HopsHive Chef Cookbook
======

Recipe to install HopsHive

## Configuration

`/srv/hops/apache-hive/conf/hive-site.xml`

## Start/Stop/Restart

```
# systemctl start/stop/restart hivemetastore
# systemctl start/stop/restart hiveserver2
```

## Logs
```
# journalctl -u hivemetastore -r
# journalctl -u hiveserver2 -r
```
