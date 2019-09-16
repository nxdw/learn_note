#!/bin/bash
#
#Description:The function of this script is th check whether the root partition occupancy rate exceeds 95%.
check_root () {
        a=`df -Th /|awk -F' ' '{print $6}'|tail -n 1|cut -d % -f 1`
        if [ $a -ge 90 ];then
                echo "[ERROR]: xx.xx.xx.xx 服务器根分区利用率超过90%，请及时处理!!!" > /root/check_root.txt
                mail -s "[1/1] xx.xx.xx.xx check_root $time" afdf@a.com </root/check_root.txt;
        else
                exit;              
        fi
}
check_root
