#!/bin/bash

iter=1
while [ $iter -le 3 ]; do
  check_vm=$(virsh list | grep "RB-PREP-MANAGER-$iter"| grep ejecutando)
  if [ "x$check_vm" != "x" ] ; then
     virsh destroy RB-PREP-MANAGER-$iter
  else
     echo "RB-PREP-MANAGER-$iter already down"
  fi
  let iter=$iter+1
done

