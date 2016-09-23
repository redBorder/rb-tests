#!/bin/bash

function check_webui(){
  e_title "rb-webui"
  service_up "nginx"
  service_up "rb-webui"
  service_up "rb-workers"
  if [ -f /opt/rb/etc/rb-webui.list ]; then
    for n in $(cat /opt/rb/etc/rb-webui.list); do
      check_output_command "curl -m 10 -s ${n}:8001 | grep '^You need to sign in or sign up before continuing.'"
    done
  fi
}
