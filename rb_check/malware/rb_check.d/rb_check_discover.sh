#!/bin/bash

function check_rb_discover(){
  e_title "rb-discover"
  service_up "rb-discover"

  local node=$(rb_nodes_with_service.rb rb-discover|tr '\n' ' ')
  if [ "x$node" != "x" ] ; then
    for n in ${node}; do
      echo "Checking functionality of rb-discover at $n"
      check_output_command "rb_manager_ssh.sh $n \"rb_discover_client.rb -r 127.0.0.1 | grep 'BEGIN RSA PRIVATE KEY'\""
    done
  fi
}
