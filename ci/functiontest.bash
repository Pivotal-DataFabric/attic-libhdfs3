#!/bin/bash

set -euo pipefail

compile_for_testing() {
  mkdir build
  pushd build
  ../bootstrap
  make
  popd
}

install_hadoop() {
  echo '***** Installing hadoop *****'

  # Configure SSH
  /sbin/sshd-keygen
  /sbin/sshd
  ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
  cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
  # TODO: need to actually run ssh localhost and echo yes to it?  Manually add localhost to known hosts?

  # Download and extract Hadoop
  wget --progress=dot:giga --no-check-certificate --no-cookies -O hadoop-2.7.1.tar.gz http://supergsego.com/apache/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz
  gunzip hadoop-2.7.1.tar.gz
  tar xvf hadoop-2.7.1.tar
  rm -f hadoop-2.7.1.tar
  mv hadoop-2.7.1 /usr/local/hadoop
  export HADOOP_PREFIX=/usr/local/hadoop

  export JAVA_HOME=/usr/java/latest
  echo "JAVA_HOME=/usr/java/latest" >> /etc/environment
  # TODO: look into hadoop_env.sh -- need to modify/run that?

  configure_hadoop_site

  # Initialize namenode
  bin/hdfs namenode -format

  # Initialize datanode
  sbin/start-dfs./sh
}

configure_hadoop_site() {
# Configure etc/hadoop/core-site.xml and etc/hadoop/hdfs-site.xml as per https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html
  cat > "${HADOOP_PREFIX}/etc/hadoop/core-site.xml" <<CoreXML
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
CoreXML

  cat > "${HADOOP_PREFIX}/etc/hadoop/hdfs-site.xml" <<SiteXML
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
SiteXML
}

run_function_tests() {
  pushd build
  make functiontest
  popd
}

_main() {
  compile_for_testing
  install_hadoop
  configure_hadoop_site
  run_function_tests
}

_main "$@"
