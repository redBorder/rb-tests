#!/bin/bash

#sudo su -l  <<TEST
COUNTER=0
echo "COUNTER=$COUNTER"
while [ $COUNTER -lt 1000 ] ; do
  if [ -f /opt/rb/etc/cluster-installed.txt ] ; then
    exit 0
  else 
    let COUNTER=COUNTER+1
    echo "Checking if cluster is ready... (\$COUNTER/1000)"
    sleep 10

  fi
done
exit 1
#TEST
