sudo hdfs dfs -mkdir -p /tmp/oozie/shell-hadoopsh/
sudo hdfs dfs -copyFromLocal job.properties /tmp/oozie/shell-hadoopsh/
sudo hdfs dfs -copyFromLocal workflow.xml /tmp/oozie/shell-hadoopsh/
