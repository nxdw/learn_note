#!/bin/bash
#
PWD=`pwd`
mail_self () {
        mail -s "$ip check_root" $1 < $PWD/check_root.txt
}


check_root () {
        a=`df -Th /|awk -F' ' '{print $6}'|tail -n 1|cut -d % -f 1`
        if [ $a -ge 90 ];then
                echo "[ERROR]:The root partition of $ip occupancy rate exceeds 90%!!!" > /$PWD/check_root.txt
        else
                exit;
        fi
}
check_root
