#!/bin/bash

check_vm=$(virsh list | grep "REDBORDER-COMMUNITY"| grep ejecutando)
if [ "x$check_vm" != "x" ] ; then 
   virsh destroy REDBORDER-COMMUNITY
else
   echo "REDBORDER-COMMUNITY already down"
fi

