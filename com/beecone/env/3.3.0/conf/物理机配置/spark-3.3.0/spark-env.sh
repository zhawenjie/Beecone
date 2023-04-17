#!/usr/bin/env bash

export SPARK_PID_DIR=/usr/local/soft/spark-3.3.0/pids
export JAVA_HOME=/usr/local/soft/jdk1.8.0_333
export SCALA_HOME=/usr/local/soft/scala-2.12.16
export SPARK_HOME=/usr/local/soft/spark-3.3.0
export SPARK_WORKER_MEMORY=1024m
export SPARK_EXECUTOR_MEMORY=2048m
export SPARK_DRIVER_MEMORY=1024m
export SPARK_DIST_CLASSPATH=$(/usr/local/soft/hadoop-3.3.3/bin/hadoop classpath)
export SPARK_LIBRARY_PATH=${SPARK_HOME}/jars
export YARN_CONF_DIR=/usr/local/soft/hadoop-3.3.3/etc/hadoop
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=24 -Dspark.history.fs.logDirectory=hdfs://masters/spark-jobhistory"
export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=zhsf999:2181,zhsf888:2181,hadoop03:2181 -Dspark.deploy.zookeeper.dir=/ha-spark"


