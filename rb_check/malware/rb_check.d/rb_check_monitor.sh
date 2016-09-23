#!/bin/bash

function check_rb_monitor() {
  e_title "rb-monitor"
  service_up "rb-monitor"

  if [ "x$MODULE_MONITOR" == "x1" ]; then
    local node=$(rb_nodes_with_service.rb rb-monitor|tr '\n' ' ')
    if [ "x$node" != "x" ]; then
      for n in ${node}; do
        echo "Checking functionality of rb-monitor at $n"
        check_topic "rb_monitor"
      done
    fi
  fi
}

