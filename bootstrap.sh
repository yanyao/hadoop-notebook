#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml


export USER=root

sed -i '/<\/configuration>/d' $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
if [[ -n $MEM_LIMIT ]];then
   MEM_LIMIT=$((MEM_LIMIT/1048576))
fi
if [[ -n $CPU_LIMIT ]];then
   CPU_LIMIT=${CPU_LIMIT%%.*}
fi

cat >> $HADOOP_PREFIX/etc/hadoop/yarn-site.xml <<- EOM
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>${MEM_LIMIT:-2048}</value>
</property>

<property>
  <name>yarn.nodemanager.resource.cpu-vcores</name>
  <value>${MY_CPU_LIMIT:-2}</value>
</property>
EOM
echo '</configuration>' >> $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

service ssh start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver
