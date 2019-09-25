#!/bin/bash
#
#Description:This script is used to make kernel perfect!!
PWD=`pwd`

modify_sysctl () {
while read line 
do
        grep $line /etc/sysctl.conf 1>/dev/null 2>&1
        if [ $? -ne 0 ];then
                #echo "$line" >> /etc/sysctl.conf
                echo "$line" 
        else
                echo "The contents have been imported!"
        fi
done < $PWD/kernel.test
}
