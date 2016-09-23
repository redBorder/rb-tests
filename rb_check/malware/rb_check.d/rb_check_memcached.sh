#!/bin/bash

function check_memcached(){
  e_title "memcached"
  service_up "memcached"

  if [ -f /opt/rb/etc/memcached.list ] ; then
    check_output_command "rb_memcache_keys.rb | grep -v \"^\(Contacting\||\s*id\)\""
  fi
}

