#!/bin/bash

cv=`jorc current_version`
lv=`jorc local_version`

v=`jorc pending_update`
rv=$?

if [ "$cv" == "$lv" ] || [ $rv -ne 0 ] 
then
  stat=0
  statustxt="OK, No updates Pending"
else
  stat=1
  statustxt="WARNING, An Update is in progress from version $lv to $cv"
fi
echo "$stat Update_Status - $statustxt"

