#!/bin/bash

set -euo pipefail

bootstrap_for_testing() {
  mkdir build
  pushd build
  ../bootstrap
  popd
}

configure_environment() {
  # Configure and launch SSH
  /sbin/sshd-keygen
  ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
  cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
  sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config # See https://gist.github.com/gasi/5691565
  /sbin/sshd &

  # Set HADOOP_PREFIX and HADOOP_HOME
  export HADOOP_PREFIX=/usr/local/hadoop
  export HADOOP_HOME=$HADOOP_PREFIX

  # Set JAVA_HOME
  export JAVA_HOME=/usr/java/latest
  sed -ri 's/export JAVA_HOME=\$\{JAVA_HOME\}/export JAVA_HOME=\/usr\/java\/latest/g' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

  # Give SSH some time to come online before we ask it to scan for keys
  sleep 2

  {
    ssh-keyscan localhost
    ssh-keyscan 0.0.0.0
    ssh-keyscan "$1"
  } >> ~/.ssh/known_hosts
}

configure_hadoop_site() {
  cat > "${HADOOP_PREFIX}/etc/hadoop/core-site.xml" <<CoreXML
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$1</value>
    </property>
</configuration>
CoreXML

  cat > "test/data/function-test.xml" <<FunctionTestXML
<configuration>

	<property>
		<name>dfs.default.uri</name>
		<value>hdfs://$1</value>
	</property>

	<property>
		<name>hadoop.security.authentication</name>
		<value>simple</value>
	</property>

	<property>
		<name>dfs.nameservices</name>
		<value>phdcluster</value>
	</property>

	<property>
		<name>dfs.default.replica</name>
		<value>3</value>
	</property>

	<property>
		<name>dfs.client.log.severity</name>
		<value>INFO</value>
	</property>

	<property>
		<name>dfs.client.read.shortcircuit</name>
		<value>true</value>
	</property>

	<property>
		<name>input.localread.blockinfo.cachesize</name>
		<value>10</value>
	</property>

	<property>
		<name>dfs.client.read.shortcircuit.streams.cache.size</name>
		<value>10</value>
	</property>

	<property>
		<name>dfs.client.use.legacy.blockreader.local</name>
		<value>true</value>
	</property>

	<property>
		<name>output.replace-datanode-on-failure</name>
		<value>false</value>
	</property>

        <property>
		<name>input.localread.mappedfile</name>
		<value>true</value>
        </property>

	<property>
		<name>dfs.domain.socket.path</name>
		<value>/var/lib/hadoop-hdfs/hdfs_domain__PORT</value>
	</property>

	<property>
		<name>dfs.ha.namenodes.phdcluster</name>
		<value>nn1,nn2</value>
	</property>

	<property>
		<name>dfs.namenode.rpc-address.phdcluster.nn1</name>
		<value>mdw:9000</value>
	</property>

	<property>
		<name>dfs.namenode.rpc-address.phdcluster.nn2</name>
		<value>smdw:9000</value>
	</property>

	<property>
		<name>dfs.namenode.http-address.phdcluster.nn1</name>
		<value>mdw:50070</value>
	</property>

	<property>
		<name>dfs.namenode.http-address.phdcluster.nn2</name>
		<value>smdw:50070</value>
	</property>

	<property>
		<name>rpc.socekt.linger.timeout</name>
		<value>20</value>
	</property>

	<property>
		<name>rpc.max.idle</name>
		<value>100</value>
	</property>

	<property>
		<name>test.get.conf</name>
		<value>success</value>
	</property>

	<property>
		<name>test.get.confint32</name>
		<value>10</value>
	</property>

	<property>
		<name>dfs.client.socketcache.expiryMsec</name>
		<value>3000</value>
	</property>

	<property>
		<name>dfs.client.socketcache.capacity</name>
		<value>1</value>
	</property>
</configuration>
FunctionTestXML

}

run_function_tests() {
  pushd build
  make functiontest 2> /dev/null
  popd
}

get_hostname_of() {
  echo "$1" | cut -d ':' -f1
}

format_hdfs_namenode() {
  echo y | "${HADOOP_HOME}"/bin/hdfs namenode -format
}

_main() {
  local hdfs_namenode_ip_port
  hdfs_namenode_ip_port=$(cat "$1")
  local hdfs_namenode_ip
  hdfs_namenode_ip=$(get_hostname_of "${hdfs_namenode_ip_port}")

  bootstrap_for_testing
  configure_environment "${hdfs_namenode_ip}"
  configure_hadoop_site "${hdfs_namenode_ip_port}"
  format_hdfs_namenode
  run_function_tests
}

_main "$@"
