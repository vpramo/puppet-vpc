#!/bin/bash

v=`jorc local_health --verbose`
rv=$?
#statustxt=`echo $v | sed 's/\n/\,/'`
if [ $rv -eq 0 ]
then
  statustxt="Deployer health is good"
else
  statustxt=`echo $v | sed 's/\n/\,/'`
fi
echo "$rv deployer_health - $statustxt"

