#!/bin/bash

function check_aerospike(){
  e_title "aerospike"
  service_up "aerospike"

  local node=$(rb_nodes_with_service.rb aerospike|tr '\n' ' ')
  if [ "x$node" != "x" ] ; then
    for n in ${node}; do
      printf "Checking query INSERT..."
      rb_manager_ssh.sh $n "aql -h $n -p 3000 -c \"INSERT INTO malware.hashScores (PK,hash,score) VALUES ('test','test',100)\"" | grep -q OK
      print_result $?
      printf "Checking query DELETE..."
      rb_manager_ssh.sh $n "aql -h $n -p 3000 -c \"DELETE FROM malware.hashScores WHERE PK='test'\"" 2> /dev/null | grep -q OK
      print_result $?
    done
  fi
}

