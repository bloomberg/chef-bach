# backup

`backup` is a chef cookbook to setup periodic HDFS inter-cluster backups.

The backup service regularly schedules HDFS distcp actions from source to backup cluster.
Distcps are run periodically using oozie coordinators and workflows.

## FUTURE: HBase, Hive, and Phoenix backups
