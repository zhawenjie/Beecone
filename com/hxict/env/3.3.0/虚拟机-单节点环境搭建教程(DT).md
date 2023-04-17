# 集群环境搭建指南

## 集群资源介绍

搭建Hadoop单机环境需要准备一台节点机，在该节点部署NameNode服务，ResourceManager服务，DataNode服务，Hive是建立在Hadoop环境上的数据仓库，用于提供类SQL服务执行MR任务，Spark号称是下一代MR计算引擎，他拥有更快的计算速度，不亚于MR的吞吐能力能等优点，但基于多线程模式的Spark计算引擎，其稳定性要低于基于多进程模式的MapReduce计算框架。

| 服务器   | NameNode | DataNode | ResourceManager | NodeManager | JournalNode | Zookeeper | ZKFC | Hive | Spark |
| -------- | -------- | -------- | --------------- | ----------- | ----------- | --------- | ---- | ---- | ----- |
| hadoop01 | √        | √        | √               | √           |             |           |      | √    | √     |

## 软件版本介绍

| Java   | jdk-8u333-linux-x64.tar.gz     | jdk1.8即可 |
| ------ | ------------------------------ | ---------- |
| Hadoop | hadoop-3.3.3.tar.gz            | 选最新     |
| MySQL  | mysql-8.0.29-el7-x86_64.tar.gz | 选最新     |
| Hive   | apache-hive-3.1.3-bin.tar.gz   | 选最新     |
| Scala  | scala-2.12.16.tgz              | 选最新     |
| Spark  | spark-3.3.0-bin-hadoop2.tgz    | 选最新     |



# 前置系统环境配置

关于Linux系统安装克隆，Java环境配置，Linux环境配置可以参考 [2.3.0](../2.3.0/虚拟机环境搭建教程(DEV).md) 版本的虚拟机环境搭建，这里不再赘述。



# Hadoop单机伪分布式搭建

## 修改配置

**注：接下来的配置在适应不同的组件时还需要做其他修改优化，当前只做简单的配置完成基本的高可用集群环境的搭建。**

```bash
# 将/usr/local/src/ 目录下的hadoop安装包解压修改名称后移动至/usr/local/soft/目录下
[root@hadoop01 src]# tar -zxvf hadoop-3.3.3.tar.gz
[root@hadoop01 src]# mv hadoop-3.3.3 ../soft/
[root@hadoop01 src]# cd .../soft/ 
[root@hadoop01 soft]# cd hadoop-3.3.3

# 在hadoop安装包的根目录下新建如下文件夹
[root@hadoop01 hadoop-3.3.3]# mkdir -p tmp
[root@hadoop01 hadoop-3.3.3]# mkdir -p logs
[root@hadoop01 hadoop-3.3.3]# mkdir -p dfs/data/journalnode
[root@hadoop01 hadoop-3.3.3]# mkdir -p dfs/edits
[root@hadoop01 hadoop-3.3.3]# mkdir -p dfs/data/datanode
[root@hadoop01 hadoop-3.3.3]# mkdir -p dfs/data/namenode

# 进入配置目录,修改配置文件
[root@hadoop01 hadoop-3.3.3]# cd /usr/local/soft/hadoop-3.3.3/etc/hadoop
```

### hadoop_env.sh

```bash
# 如果下面的环境变量不生效，请移步配置在/etc/profile中
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_JOURNALNODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root
export HDFS_ZKFC_USER=root

# 修改hadoop_env.sh启动环境变量，Hadoop独立配置。
export JAVA_HOME=/usr/local/soft/jdk1.8.0_333
export HADOOP_CONF_DIR=/usr/local/soft/hadoop-3.3.3/etc/hadoop
```

### core-site.xml

```xml
<configuration>
    <property>
          <name>fs.defaultFS</name>
          <value>hdfs://hadoop01:9000</value>
    </property>
    <property>
          <name>hadoop.tmp.dir</name>
          <value>/usr/local/soft/hadoop-3.3.3/tmp</value>
    </property>
    <property>
        <!--设置缓存大小，默认4kb-->
        <name>io.file.buffer.size</name>
        <value>4096</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>
</configuration>
```

### hdfs-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
        <!--设置副本个数-->
        <property>
            <name>dfs.replication</name>
            <value>1</value>
        </property>
        <!--设置namenode.name目录-->
        <property>
            <name>dfs.namenode.name.dir</name>
            <value>/usr/local/soft/hadoop-3.3.3/dfs/data/namenode</value>
        </property>
        <!--设置namenode.data目录-->
        <property>
            <name>dfs.datanode.data.dir</name>
            <value>/usr/local/soft/hadoop-3.3.3/dfs/data/datanode</value>
        </property>
        <property>
            <!--设置hdfs操作权限，false表示任何用户都可以在hdfs上操作文件-->
            <name>dfs.permissions</name>
            <value>false</value>
        </property>
		<property>
            <name>dfs.ha.fencing.methods</name>
            <value>sshfence</value>
        </property>
        <!--使用sshfence隔离机制时需要ssh免登录-->
        <property>
            <name>dfs.ha.fencing.ssh.private-key-files</name>
            <value>/root/.ssh/id_rsa</value>
        </property>
</configuration>
```

### yarn-site.xml

```xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>
    <property>
        <!--指定主resourcemanager的地址-->
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop01</value>
    </property>
    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
    </property>
    <property>
        <!--开启日志聚集功能-->
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <property>
        <!--配置日志保留7天-->
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
</configuration>
```

### mapred-site.xml

```xml
	<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http,//www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <!-- 历史服务器端地址 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>hadoop01:10020</value>
	</property>
    <!-- 历史服务器 web 端地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>hadoop01:19888</value>
    </property>
    
    <!--下面的配置在Hadoop-3.X系列中是不需要的，但是在Hadoop-3.X则必须添加否则任务无法启动-->
    <property>
      <name>yarn.app.mapreduce.am.env</name>
      <value>HADOOP_MAPRED_HOME=/usr/local/soft/hadoop-3.3.3</value>
    </property>
    <property>
      <name>mapreduce.map.env</name>
      <value>HADOOP_MAPRED_HOME=/usr/local/soft/hadoop-3.3.3</value>
    </property>
    <property>
      <name>mapreduce.reduce.env</name>
      <value>HADOOP_MAPRED_HOME=/usr/local/soft/hadoop-3.3.3</value>
    </property>
</configuration>
```

### works

```bash
# 因为美国弗洛伊德案导致原先的slaves可能存在歧视黑人的问题，因此在后续版本中slaves文件名被替换为works
hadoop01
```



### 添加环境变量

```bash

export HADOOP_HOME=/usr/local/soft/hadoop-3.3.3
export PATH=.:${PATH}:${JAVA_HOME}/bin:${JRE_HOME}/bin:${HADOOP_HOME}/bin
```

## 启动集群

### 格式化NameNode（仅初次需要）

```bash
# 在hadoop01上执行NameNode格式化操作，格式化NameNode。使用如下命令，得到如图所示的提示信息，则表示NameNode格式化成功。
[root@hadoop01 /]# hdfs namenode -format
************************************************************/
2022-07-18 10:28:57,620 INFO namenode.NameNode: registered UNIX signal handlers for [TERM, HUP, INT]
2022-07-18 10:28:57,992 INFO namenode.NameNode: createNameNode [-format]
2022-07-18 10:29:00,003 INFO common.Util: Assuming 'file' scheme for path /usr/local/bigdata/hadoop-3.3.3/dfs/data/namenode in configuration.
2022-07-18 10:29:00,004 INFO common.Util: Assuming 'file' scheme for path /usr/local/bigdata/hadoop-3.3.3/dfs/data/namenode in configuration.
2022-07-18 10:29:00,021 INFO namenode.NameNode: Formatting using clusterid: CID-6cca689b-861d-4e77-a78d-113eb2be6e46
2022-07-18 10:29:00,126 INFO namenode.FSEditLog: Edit logging is async:true
2022-07-18 10:29:00,426 INFO namenode.FSNamesystem: KeyProvider: null
2022-07-18 10:29:00,430 INFO namenode.FSNamesystem: fsLock is fair: true
2022-07-18 10:29:00,430 INFO namenode.FSNamesystem: Detailed lock hold time metrics enabled: false
2022-07-18 10:29:00,518 INFO namenode.FSNamesystem: fsOwner                = root (auth:SIMPLE)
2022-07-18 10:29:00,518 INFO namenode.FSNamesystem: supergroup             = supergroup
2022-07-18 10:29:00,518 INFO namenode.FSNamesystem: isPermissionEnabled    = true
2022-07-18 10:29:00,518 INFO namenode.FSNamesystem: isStoragePolicyEnabled = true
2022-07-18 10:29:00,519 INFO namenode.FSNamesystem: HA Enabled: false
2022-07-18 10:29:00,633 INFO common.Util: dfs.datanode.fileio.profiling.sampling.percentage set to 0. Disabling file IO profiling
2022-07-18 10:29:00,656 INFO blockmanagement.DatanodeManager: dfs.block.invalidate.limit: configured=1000, counted=60, effected=1000
2022-07-18 10:29:00,656 INFO blockmanagement.DatanodeManager: dfs.namenode.datanode.registration.ip-hostname-check=true
2022-07-18 10:29:00,663 INFO blockmanagement.BlockManager: dfs.namenode.startup.delay.block.deletion.sec is set to 000:00:00:00.000
2022-07-18 10:29:00,663 INFO blockmanagement.BlockManager: The block deletion will start around 2022 Jul 18 10:29:00
2022-07-18 10:29:00,666 INFO util.GSet: Computing capacity for map BlocksMap
2022-07-18 10:29:00,666 INFO util.GSet: VM type       = 64-bit
2022-07-18 10:29:00,687 INFO util.GSet: 2.0% max memory 5.2 GB = 106.8 MB
2022-07-18 10:29:00,688 INFO util.GSet: capacity      = 2^24 = 16777216 entries
2022-07-18 10:29:00,718 INFO blockmanagement.BlockManager: Storage policy satisfier is disabled
2022-07-18 10:29:00,719 INFO blockmanagement.BlockManager: dfs.block.access.token.enable = false
2022-07-18 10:29:00,730 INFO blockmanagement.BlockManagerSafeMode: dfs.namenode.safemode.threshold-pct = 0.999
2022-07-18 10:29:00,731 INFO blockmanagement.BlockManagerSafeMode: dfs.namenode.safemode.min.datanodes = 0
2022-07-18 10:29:00,731 INFO blockmanagement.BlockManagerSafeMode: dfs.namenode.safemode.extension = 30000
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: defaultReplication         = 1
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: maxReplication             = 512
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: minReplication             = 1
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: maxReplicationStreams      = 2
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: redundancyRecheckInterval  = 3000ms
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: encryptDataTransfer        = false
2022-07-18 10:29:00,732 INFO blockmanagement.BlockManager: maxNumBlocksToLog          = 1000
2022-07-18 10:29:00,826 INFO namenode.FSDirectory: GLOBAL serial map: bits=29 maxEntries=536870911
2022-07-18 10:29:00,826 INFO namenode.FSDirectory: USER serial map: bits=24 maxEntries=16777215
2022-07-18 10:29:00,826 INFO namenode.FSDirectory: GROUP serial map: bits=24 maxEntries=16777215
2022-07-18 10:29:00,826 INFO namenode.FSDirectory: XATTR serial map: bits=24 maxEntries=16777215
2022-07-18 10:29:00,852 INFO util.GSet: Computing capacity for map INodeMap
2022-07-18 10:29:00,852 INFO util.GSet: VM type       = 64-bit
2022-07-18 10:29:00,852 INFO util.GSet: 1.0% max memory 5.2 GB = 53.4 MB
2022-07-18 10:29:00,852 INFO util.GSet: capacity      = 2^23 = 8388608 entries
2022-07-18 10:29:01,563 INFO namenode.FSDirectory: ACLs enabled? true
2022-07-18 10:29:01,563 INFO namenode.FSDirectory: POSIX ACL inheritance enabled? true
2022-07-18 10:29:01,563 INFO namenode.FSDirectory: XAttrs enabled? true
2022-07-18 10:29:01,564 INFO namenode.NameNode: Caching file names occurring more than 10 times
2022-07-18 10:29:01,573 INFO snapshot.SnapshotManager: Loaded config captureOpenFiles: false, skipCaptureAccessTimeOnlyChange: false, snapshotDiffAllowSnapRootDescendant: true, maxSnapshotLimit: 65536
2022-07-18 10:29:01,578 INFO snapshot.SnapshotManager: SkipList is disabled
2022-07-18 10:29:01,587 INFO util.GSet: Computing capacity for map cachedBlocks
2022-07-18 10:29:01,587 INFO util.GSet: VM type       = 64-bit
2022-07-18 10:29:01,587 INFO util.GSet: 0.25% max memory 5.2 GB = 13.4 MB
2022-07-18 10:29:01,587 INFO util.GSet: capacity      = 2^21 = 2097152 entries
2022-07-18 10:29:01,605 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.window.num.buckets = 10
2022-07-18 10:29:01,606 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.num.users = 10
2022-07-18 10:29:01,606 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.windows.minutes = 1,5,25
2022-07-18 10:29:01,613 INFO namenode.FSNamesystem: Retry cache on namenode is enabled
2022-07-18 10:29:01,613 INFO namenode.FSNamesystem: Retry cache will use 0.03 of total heap and retry cache entry expiry time is 600000 millis
2022-07-18 10:29:01,617 INFO util.GSet: Computing capacity for map NameNodeRetryCache
2022-07-18 10:29:01,617 INFO util.GSet: VM type       = 64-bit
2022-07-18 10:29:01,617 INFO util.GSet: 0.029999999329447746% max memory 5.2 GB = 1.6 MB
2022-07-18 10:29:01,617 INFO util.GSet: capacity      = 2^18 = 262144 entries
2022-07-18 10:29:01,685 INFO namenode.FSImage: Allocated new BlockPoolId: BP-681817286-10.2.12.157-1658111341670
2022-07-18 10:29:01,929 INFO common.Storage: Storage directory /usr/local/bigdata/hadoop-3.3.3/dfs/data/namenode has been successfully formatted.
2022-07-18 10:29:01,976 INFO namenode.FSImageFormatProtobuf: Saving image file /usr/local/bigdata/hadoop-3.3.3/dfs/data/namenode/current/fsimage.ckpt_0000000000000000000 using no compression
2022-07-18 10:29:02,203 INFO namenode.FSImageFormatProtobuf: Image file /usr/local/bigdata/hadoop-3.3.3/dfs/data/namenode/current/fsimage.ckpt_0000000000000000000 of size 399 bytes saved in 0 seconds .
2022-07-18 10:29:02,254 INFO namenode.NNStorageRetentionManager: Going to retain 1 images with txid >= 0
2022-07-18 10:29:02,329 INFO namenode.FSNamesystem: Stopping services started for active state
2022-07-18 10:29:02,330 INFO namenode.FSNamesystem: Stopping services started for standby state
2022-07-18 10:29:02,339 INFO namenode.FSImage: FSImageSaver clean checkpoint: txid=0 when meet shutdown.
2022-07-18 10:29:02,340 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at hadoop01/192.168.110.121
************************************************************/
```

### 启动服务

```bash
# 可以通过./start-dfs.sh 和 ./start-yarn.sh 来启动hadoop服务，也可以通过./start-all.sh来启动，这里就简单粗暴一点直接通过./start-all.sh来启动了
[root@zhsffydjcs sbin]# ./start-all.sh
Starting namenodes on [hadoop01]
Starting datanodes
Starting secondary namenodes [hadoop01]
Starting resourcemanager
Starting nodemanagers

# 查看启动的服务是否正常
[root@hadoop01 sbin]# jps
21600 DataNode
22855 Jps
22254 NodeManager
22131 ResourceManager
21784 SecondaryNameNode
21466 NameNode
```

### 启动JobhistoryServer

```bash
[root@hadoop01 sbin]# mapred --daemon start historyserver

# 此时该节点多了一个 JobHistoryServer 服务
[root@hadoop01 sbin]# jps
25280 NodeManager
25156 ResourceManager
25508 JobHistoryServer
25737 Jps
24784 SecondaryNameNode
24475 NameNode
24606 DataNode
```



# MySQL环境配置

关于MySQL的安装配置，可以参考 [3.3.0](../3.3.0/虚拟机环境搭建教程(DEV).md) 版本的环境搭建，这里不再赘述。



# Hive环境搭建

## 简介

Hive是基于Hadoop的一个数据仓库工具，用来进行数据提取、转化、加载，这是一种可以存储、查询和分析存储在Hadoop中的大规模数据的机制。hive数据仓库工具能将结构化的数据文件映射为一张数据库表，并提供SQL查询功能，能将SQL语句转变成MapReduce任务来执行。Hive的优点是学习成本低，可以通过类似SQL语句实现快速MapReduce统计，使MapReduce变得更加简单，而不必开发专门的MapReduce应用程序。Hive十分适合对数据仓库进行统计分析。

## 下载Hive

同样选择下载Apache Hive的时候我们可以选择[官网](https://www.apache.org/dyn/closer.cgi/hive/)下载也可以选择国内镜像（[清华源](https://mirrors.tuna.tsinghua.edu.cn/apache/hive/)）下载，区别在于官网有所有版本的Hive而国内的镜像只有部分版本提供。   

| [apache-hive-3.1.3-bin.tar.gz](https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz) | 2018-05-22 18:45 | 293M |
| ------------------------------------------------------------ | ---------------- | ---- |
|                                                              |                  |      |

## 配置Hive

### 添加Connector

Hive的元数据库是MySQL，所以我们还需要**把mysql的驱动mysql-connector-java-8.0.29.jar上传至.../hive-3.1.3/lib目录下**.

```bash
#防止直接修改出错，先将需要配置的文件复制一份再修改  
[root@hadoop01 conf]# cp hive-default.xml.template hive-default.xml
[root@hadoop01 conf]# cp hive-env.sh.template hive-env.sh
[root@hadoop01 conf]# cp hive-log4j2.properties.template hive-log4j.properties
[root@hadoop01 conf]# cp hive-default.xml hive-site.xml
```

### hive-env.sh

```bash
export JAVA_HOME=/usr/local/soft/jdk1.8.0_333

# Set HADOOP_HOME to point to a specific hadoop install directory
export HADOOP_HOME=/usr/local/soft/hadoop-3.3.3

# Hive Configuration Directory can be controlled by:
export HIVE_HOME=/usr/local/soft/hive-3.1.3
export HIVE_CONF_DIR=/usr/local/soft/hive-3.1.3/conf

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
export HIVE_AUX_JARS_PATH=/usr/local/soft/hive-3.1.3/lib
```

### hive-log4j2.properties

```properties
property.hive.log.dir = /usr/local/soft/hive-3.1.3/logs
```

### hive-site.xml

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
     <!-- 查询数据时 显示出列的名字 -->
        <name>hive.cli.print.header</name>
        <value>true</value>
    </property>
    <property>
     <!-- 在命令行中显示当前所使用的数据库 -->
        <name>hive.cli.print.current.db</name>
        <value>true</value>
    </property>
    <property>
     <!-- 默认数据仓库存储的位置，该位置为HDFS上的路径 -->
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <!-- 8.x -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://hadoop01:3306/metastore?createDatabaseIfNotExist=true&amp;useSSL=false&amp;serverTimezone=GMT</value>
    </property>
    <!-- 8.x -->
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>root</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>123456</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://hadoop01:9083</value> 
    </property>
</configuration>
```

### 配置环境变量

```bash
# 修改系统环境  
[root@hadoop01 conf]# vim /etc/profile
export HIVE_HOME=/usr/local/soft/hive-3.1.3
export PATH=${PATH}:${JAVA_HOME}/bin:${JRE_HOME}/bin:${ZOOKEEPER_HOME}/bin:${HADOOP_HOME}/bin:${SCALA_HOME}/bin:${SPARK_HOME}/bin:${MYSQL_HOME}/bin:${HIVE_HOME}/bin


# 记得刷新环境变量
[root@hadoop01 conf]# source /etc/profile
```

### 初始化元数据库

### 添加Connector

Hive的元数据库是MySQL，所以我们还需要**把mysql的驱动mysql-connector-java-8.0.29.jar上传至.../hive-3.0.0/lib目录下**.

```bash
# 以上配置完成后，需要初始化mysql元数据库，所谓初始化就是在mysql中创建hive的元数据库也就是我们配置在javax.jdo.option.ConnectionURL的metastore，使用如下命令进行配置：
[root@hadoop01 bin]# ./schematool -dbType mysql -initSchema root 123456 --verbose
......
......
0: jdbc:mysql://hadoop01:3306/metastore2> CREATE TABLE `I_SCHEMA` ( `SCHEMA_ID` BIGINT PRIMARY KEY, `SCHEMA_TYPE` INTEGER NOT NULL, `NAME` VARCHAR(256), `DB_ID` BIGINT, `COMPATIBILITY` INTEGER NOT NULL, `VALIDATION_LEVEL` INTEGER NOT NULL, `CAN_EVOLVE` bit(1) NOT NULL, `SCHEMA_GROUP` VARCHAR(256), `DESCRIPTION` VARCHAR(4000), FOREIGN KEY (`DB_ID`) REFERENCES `DBS` (`DB_ID`), KEY `UNIQUE_NAME` (`NAME`) ) ENGINE=InnoDB DEFAULT CHARSET=latin1
No rows affected (0.017 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> CREATE TABLE `SCHEMA_VERSION` ( `SCHEMA_VERSION_ID` bigint primary key, `SCHEMA_ID` BIGINT, `VERSION` INTEGER NOT NULL, `CREATED_AT` BIGINT NOT NULL, `CD_ID` BIGINT, `STATE` INTEGER NOT NULL, `DESCRIPTION` VARCHAR(4000), `SCHEMA_TEXT` mediumtext, `FINGERPRINT` VARCHAR(256), `SCHEMA_VERSION_NAME` VARCHAR(256), `SERDE_ID` bigint, FOREIGN KEY (`SCHEMA_ID`) REFERENCES `I_SCHEMA` (`SCHEMA_ID`), FOREIGN KEY (`CD_ID`) REFERENCES `CDS` (`CD_ID`), FOREIGN KEY (`SERDE_ID`) REFERENCES `SERDES` (`SERDE_ID`), KEY `UNIQUE_VERSION` (`SCHEMA_ID`, `VERSION`) ) ENGINE=InnoDB DEFAULT CHARSET=latin1
No rows affected (0.017 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> CREATE TABLE REPL_TXN_MAP ( RTM_REPL_POLICY varchar(256) NOT NULL, RTM_SRC_TXN_ID bigint NOT NULL, RTM_TARGET_TXN_ID bigint NOT NULL, PRIMARY KEY (RTM_REPL_POLICY, RTM_SRC_TXN_ID) ) ENGINE=InnoDB DEFAULT CHARSET=latin1
No rows affected (0.013 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> CREATE TABLE RUNTIME_STATS ( RS_ID bigint primary key, CREATE_TIME bigint NOT NULL, WEIGHT bigint NOT NULL, PAYLOAD blob ) ENGINE=InnoDB DEFAULT CHARSET=latin1
No rows affected (0.01 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> CREATE INDEX IDX_RUNTIME_STATS_CREATE_TIME ON RUNTIME_STATS(CREATE_TIME)
No rows affected (0.009 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> INSERT INTO VERSION (VER_ID, SCHEMA_VERSION, VERSION_COMMENT) VALUES (1, '3.1.0', 'Hive release version 3.1.0')
1 row affected (0.002 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40101 SET character_set_client = @saved_cs_client */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40101 SET SQL_MODE=@OLD_SQL_MODE */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */
No rows affected (0.001 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */
No rows affected (0.002 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */
No rows affected (0.001 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> /*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */
No rows affected (0 seconds)
0: jdbc:mysql://hadoop01:3306/metastore2> !closeall
Closing: 0: jdbc:mysql://hadoop01:3306/metastore2?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=GMT
beeline>
beeline> Initialization script completed
schemaTool completed
```

## 启动Hive

### 启动元数据服务

```bash
[root@hadoop01 bin]# nohup hive --service metastore &
[root@hadoop01 bin]# nohup hive --service hiveserver2 &
```

## 测试

进入hive客户端测试Hive的功能，验证如下CRUD的功能是否正常，如果正常则表示Hive环境搭建成功。到此Hive可以通过Hive Cli / beeline cli/ Java JDBC的方式进行连接（可以自己验证）。

```bash
[root@hadoop02 bin]# hive
...
Logging initialized using configuration in jar:file:/usr/local/soft/hive-3.1.3/lib/hive-common-3.1.3.jar!/hive-log4j2.properties Async: true
Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.
hive (default)> set hive.execution.engine;
hive.execution.engine=mr
hive (default)> show databases;
OK
database_name
default
Time taken: 0.431 seconds, Fetched: 1 row(s)

# 创建数据库
hive (default)> create database ods;
OK
Time taken: 0.104 seconds

# 创建表
hive (default)> create table if not exists ods.biss(
              >     id string,
              >     code string
              > )partitioned by(`dt` string)
              > ;
OK
Time taken: 0.179 seconds

# 插入数据，会启动MR服务
hive (default)> insert overwrite table ods.biss partition(dt=202206011505)
              > select * from (
              > select '1' as id , 'jia001' as code
              > union all
              > select '2' as id , 'xia002' as code
              > union all
              > select '3' as id , 'tia003' as code
              > ) aa;
Query ID = root_20220626193550_93a49457-9fb5-49e2-9390-c5835f12a194
Total jobs = 3
Launching Job 1 out of 3
Number of reduce tasks not specified. Estimated from input data size: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapreduce.job.reduces=<number>
Starting Job = job_1656243011117_0001, Tracking URL = http://hadoop01:8088/proxy/application_1656243011117_0001/
Kill Command = /usr/local/soft/hadoop-3.3.3/bin/mapred job  -kill job_1656243011117_0001
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2022-06-26 19:36:01,999 Stage-1 map = 0%,  reduce = 0%
2022-06-26 19:36:03,052 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 3.68 sec
MapReduce Total cumulative CPU time: 3 seconds 680 msec
Ended Job = job_1656243011117_0001
Stage-4 is selected by condition resolver.
Stage-3 is filtered out by condition resolver.
Stage-5 is filtered out by condition resolver.
Moving data to directory hdfs://masters/user/hive/warehouse/ods.db/biss/dt=202206011505/.hive-staging_hive_2022-06-26_19-35-50_897_1139040472351276912-1/-ext-10000
Loading data to table ods.biss partition (dt=202206011505)
MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 3.68 sec   HDFS Read: 23432 HDFS Write: 564526 SUCCESS
Total MapReduce CPU Time Spent: 3 seconds 680 msec
OK
aa.id   aa.code
Time taken: 14.03 seconds

# 查询数据，回启动MR计算
hive (default)> select id, count(*) from ods.biss group by id;
Query ID = root_20220626193611_260d52b7-8134-46f4-94c4-26efc31f8847
Total jobs = 1
Launching Job 1 out of 1
Number of reduce tasks not specified. Estimated from input data size: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapreduce.job.reduces=<number>
Starting Job = job_1656243011117_0002, Tracking URL = http://hadoop01:8088/proxy/application_1656243011117_0002/
Kill Command = /usr/local/soft/hadoop-3.3.3/bin/mapred job  -kill job_1656243011117_0002
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2022-06-26 19:36:21,062 Stage-1 map = 0%,  reduce = 0%
2022-06-26 19:36:22,124 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 6.7 sec
MapReduce Total cumulative CPU time: 6 seconds 700 msec
Ended Job = job_1656243011117_0002
MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 6.7 sec   HDFS Read: 19564 HDFS Write: 556130 SUCCESS
Total MapReduce CPU Time Spent: 6 seconds 700 msec
OK
id      _c1
1       1
2       1
3       1
Time taken: 12.494 seconds, Fetched: 3 row(s)
```



# Scala环境配置

关于Scala环境配置，可以参考 [2.3.0](../2.3.0/虚拟机环境搭建教程(DEV).md) 版本的虚拟机环境搭建，这里不再赘述。



# Spark单机环境搭建（Spark ON Yarn）

## 下载软件

| [spark-3.3.0-bin-hadoop3.tgz](https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz) | 2018-02-22 19:54 | 29M  |
| ------------------------------------------------------------ | ---------------- | ---- |
|                                                              |                  |      |

## 编译Spark

```bash
# 修改名字便于配置
[root@hadoop01 soft]# tar -zxvf spark-3.3.0-bin-hadoop3.tgz
[root@hadoop01 soft]# mv spark-3.3.0-bin-hadoop3 spark-3.3.0
[root@hadoop01 spark-3.3.0]# cd conf/

# 拷贝需要修改的配置文件，防止出错的时候恢复
[root@hadoop01 conf]# cp spark-env.sh.template spark-env.sh
[root@hadoop01 conf]# cp slaves.template slaves
```



## 配置修改

### spark-env.sh

```bash
# 在spark安装包的根目录下新建文件夹
[root@hadoop02 spark-3.3.0]# mkdir pids

export SPARK_PID_DIR=/usr/local/soft/spark-3.3.0/pids
export JAVA_HOME=/usr/local/soft/jdk1.8.0_333
export SCALA_HOME=/usr/local/soft/scala-2.12.16
export HADOOP_HOME=/usr/local/soft/hadoop-3.3.3
export HADOOP_CONF_DIR=/usr/local/soft/hadoop-3.3.3/etc/hadoop
export HADOOP_YARN_CONF_DIR=/usr/local/soft/hadoop-3.3.3/etc/hadoop
export SPARK_HOME=/usr/local/soft/spark-3.3.0
export SPARK_WORKER_MEMORY=1024m
export SPARK_EXECUTOR_MEMORY=1024m
export SPARK_DRIVER_MEMORY=1024m
export SPARK_DIST_CLASSPATH=$(/usr/local/soft/hadoop-3.3.3/bin/hadoop classpath)
export SPARK_LIBRARY_PATH=${SPARK_HOME}/jars
export SPARK_MASTER_HOST=hadoop01
export SPARK_MASTER_PORT=7077
export YARN_CONF_DIR=/opt/software/hadoop-2.7.7/etc/hadoop
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=24 -Dspark.history.fs.logDirectory=hdfs://hadoop01:9000/spark-jobhistory"
```



### spark-defaults.conf

```bash
spark.master                     spark://hadoop01:7077
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://hadoop01:9000/spark-jobhistory
spark.yarn.historyServer.address               hadoop01:18080
spark.master.rest.enabled        true
```



### slaves

```bash
# A Spark Worker will be started on each of the machines listed below.
hadoop01
```

### 拷贝jar包

```bash
# 将Hive的lib目录下的指定jar包拷贝到Spark的jars目录下：
hive-beeline
hive-cli
hive-exec
hive-jdbc
hive-metastore

[root@hadoop01 lib]# cd /usr/local/soft/hive-3.1.3/lib

[root@hadoop01 lib]# cp hive-beeline-3.1.3.jar hive-cli-3.1.3.jar hive-exec-3.1.3.jar hive-jdbc-3.1.3.jar hive-metastore-3.1.3.jar /usr/local/soft/spark-3.3.0/jars/
```

```bash
# 将Spark的jars目录下的指定jar包拷贝到Hive的lib目录下：
spark-network-common
spark-core_
chill-java
chill_
jackson-module-paranamer
jackson-module-scala
jersey-container-servlet-core
jersey-server
json4s-ast
kryo-shaded
minlog
scala-xml
spark-launcher
spark-network-shuffle
spark-unsafe
xbean-asm9-shaded

[root@hadoop01 jars]# cd /usr/local/soft/spark-3.3.0/jars/

[root@hadoop01 jars]# cp spark-network-common_2.12-3.3.0.jar spark-core_2.12-3.3.0.jar chill-java-0.10.0.jar chill_2.12-0.10.0.jar jackson-module-scala_2.12-2.13.3.jar jersey-container-servlet-core-2.34.jar jersey-server-2.34.jar json4s-ast_2.12-3.7.0-M11.jar kryo-shaded-4.0.2.jar minlog-1.3.0.jar scala-xml_2.12-1.2.0.jar spark-launcher_2.12-3.3.0.jar spark-network-shuffle_2.12-3.3.0.jar spark-unsafe_2.12-3.3.0.jar xbean-asm9-shaded-4.20.jar /usr/local/soft/hive-3.1.3/lib/
```

```bash
# 将hadoop中的yarn-site.xml、hdfs-site.xml以及Hive的hive-site.xml放入spark的conf中
[root@hadoop01 jars]# cd /usr/local/soft

[root@hadoop01 soft]# cp hadoop-3.3.3/etc/hadoop/hdfs-site.xml spark-3.3.0/conf/
[root@hadoop01 soft]# cp hadoop-3.3.3/etc/hadoop/yarn-site.xml spark-3.3.0/conf/
[root@hadoop01 soft]# cp hive-3.1.3/conf/hive-site.xml spark-3.3.0/conf/
```

为了使各个节点都能够使用 Spark 引擎进行计算，需要将Spark的jars目录下所有依赖包上传至HDFS

```bash
[root@hadoop01 soft]# hdfs dfs -mkdir /spark-jars
[root@hadoop01 soft]# hdfs dfs -mkdir /spark-hive-jobhistory
[root@hadoop01 soft]# hdfs dfs -mkdir /spark-jobhistory
[root@hadoop01 soft]# cd /usr/local/soft/spark-3.3.0/jars
[root@hadoop01 jars]# hdfs dfs -put *.jar /spark-jars
```

### 配置环境变量

```bash
# 修改每一个节点的环境变量
[root@hadoop01 jars]# vim /etc/profile

export SPARK_HOME=/usr/local/soft/spark-3.3.0
export PATH=.:${PATH}:${JAVA_HOME}/bin:${JRE_HOME}/bin:${ZOOKEEPER_HOME}/bin:${HADOOP_HOME}/bin:$MYSQL_HOME/bin:${HIVE_HOME}/bin:$SCAL_HOME/bin:${SPARK_HOME}/bin
```

## 启动集群

```bash
# 在hadoop01上启动spark集群
[root@hadoop01 jars]# cd /usr/local/soft/spark-3.3.0/sbin
[root@hadoop01 sbin]# ./start-all.sh
starting org.apache.spark.deploy.master.Master, logging to /usr/local/soft/spark-3.3.0/logs/spark-root-org.apache.spark.deploy.master.Master-1-hadoop01.out
hadoop01: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/soft/spark-3.3.0/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-hadoop01.out
```

## 测试

```bash
# 测试 spark-sql
[root@hadoop01 bin]# spark-sql

spark-sql (default)> select id, count(*) from ods.biss group by id;
22/07/21 15:29:13 WARN SessionState: METASTORE_FILTER_HOOK will be ignored, since hive.security.authorization.manager is set to instance of HiveAuthorizerFactory.
id      count(1)
1       1
2       1
3       1
Time taken: 6.843 seconds, Fetched 3 row(s)
spark-sql (default)>

```



