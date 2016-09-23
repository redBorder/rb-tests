#!/bin/bash

function check_hadoop_namenode(){
  e_title "hadoop_namenode"
  service_up "hadoop_namenode"
}

function check_hadoop_journalnode(){
  e_title "hadoop_journalnode"
  service_up "hadoop_journalnode"
}

function check_hadoop_datanode(){
  e_title "hadoop_datanode"
  service_up "hadoop_datanode"
}

function check_hadoop_historyserver(){
  e_title "hadoop_historyserver"
  service_up "hadoop_historyserver"
}

function check_hadoop_zkfc(){
  e_title "hadoop_zkfc"
  service_up "hadoop_zkfc"
}

function check_hadoop_nodemanager(){
  e_title "hadoop_nodemanager"
  service_up "hadoop_nodemanager"
  if [ -f /opt/rb/etc/hadoop_nodemanager.list ]; then
    for n in $(cat /opt/rb/etc/hadoop_nodemanager.list); do
      check_output_command "curl -m 10 -s ${n}:8042/node|tr '\n' ' '|grep Containers|grep VCores|grep LastNodeHealthTime"
    done
  fi
}

function check_hadoop_resourcemanager(){
  e_title "hadoop_resourcemanager"
  service_up "hadoop_resourcemanager"
  if [ -f /opt/rb/etc/hadoop_resourcemanager.list ]; then
    for n in $(cat /opt/rb/etc/hadoop_resourcemanager.list); do
      check_output_command "curl -m 10 -s ${n}:8021/cluster|tr '\n' ' '|grep Applications|grep Submitted|grep RUNNING"
    done
    if [ $SAMZA -eq 1 ]; then
      check_output_command "rb_samza.sh -l 2>/dev/null|grep enrichment_|grep RUNNING |grep default"
      check_output_command "rb_samza.sh -l 2>/dev/null|grep indexing_|grep RUNNING |grep default"
    fi
  fi
}

function check_hadoop_hdfs(){
  e_title "hadoop HDFS functional tests"

  local datanode=$(rb_nodes_with_service.rb hadoop_datanode|tr '\n' ' ')
  if [ "x$datanode" != "x" ];then
    local namenode=$(rb_nodes_with_service.rb hadoop_namenode|tr '\n' ' ')
    if [ "x$namenode" != "x" ];then
      touch /tmp/testhdfs1
      check_command "hdfs dfs -ls /user/ &> /dev/null"
      check_command "hdfs dfs -put /tmp/testhdfs1 /user/testhdfs1 &> /dev/null"
      check_command "hdfs dfs -get /user/testhdfs1 /tmp/testhdfs2 &> /dev/null"
      check_command "hdfs dfs -rm /user/testhdfs* &> /dev/null"
      rm -rf /tmp/testhdfs1 &> /dev/null
      rm -rf /tmp/testhdfs2 &> /dev/null
    else
      echo "HFDS is unavailable - hadoop_namenode is DOWN"
      echo ""
      ret=0
    fi
  else
    echo "HFDS is unavailable - hadoop_datanode is DOWN"
    echo ""
    ret=0
  fi

  CHECKEXEC=1
  return $ret
}

