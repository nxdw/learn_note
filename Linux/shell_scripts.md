#!/bin/bash
#
#Description:The function of this script is th check whether the root partition occupancy rate exceeds 90%.
check_root () {
        a=`df -Th /|awk -F' ' '{print $6}'|tail -n 1|cut -d % -f 1`
        if [ $a -ge 90 ];then
                echo $a;
        else
                echo "no promble;"              
        fi
}
check_root
