#!/bin/bash

NumberVirtualMachine=$1

if [ "x$NumberVirtualMachine" != "x" ] ; then
    check_vm=$(virsh list | grep "REDBORDER-MANAGER-$NumberVirtualMachine"| grep ejecutando)
    if [ "x$check_vm" != "x" ] ; then 
       virsh destroy REDBORDER-MANAGER-$NumberVirtualMachine
    else
       echo "REDBORDER-MANAGER-$NumberVirtualMachine already down"
    fi
else
    echo "Usage $(basename $0) <NUMBER_VIRTUAL_MACHINE>"
fi
