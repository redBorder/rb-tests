#!/bin/bash

CONTADOR=0
ERROR="YES"
HOST=$1

while [ "$CONTADOR" -lt "200" -a "$ERROR" != "NO" -a "x$HOST" != "x" ] ; do
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/rb-tests/.ssh/id_rsa_jenkins root@$HOST -p 22 -v exit
    #/opt/keys/id_rsa_jenkins root@$HOST -p 6666 -v exit    
    if [ $? -eq 0 ] ; then
    	ERROR="NO"
    fi    
    sleep 10
    let CONTADOR=CONTADOR+1
	echo "CONTADOR = $CONTADOR"    
done
if [ "$ERROR" != "NO" ] ; then
	exit 1
fi

