#!/bin/bash
#
PWD=`pwd`
get_ip () {
        while true
        do
                read -p "Please input this host's ip: " ip
                read -p "Are you sure?,yes or no: " answer
                if [ x$answer =  xyes ]; then
                        echo "This host's ip is:$ip "
                        sed -i "/mail_self/i\ip=$ip" $PWD/check_root.sh
                        break
                fi
        done
}

get_mail () {
        while true
        do
                read -p "Please input the manager's email address: " mail
                read -p "Are you sure?,yes or no: " answer
                if [ x$answer =  xyes ]; then
                        echo "The manager's email address is:$mail "
                        sed -i "/echo/a\mail_self $mail" $PWD/check_root.sh
                        break
                fi
        done

}
install () {
get_ip
get_mail
while true
do
        read -p "Are you add a new manager?[yes/no]: " answer
        if [ x$answer = xyes ];then
                get_mail
        else
                break
        fi
done
echo "0 23 * * * /bin/bash $PWD/check_root.sh" >> /etc/crontab
}
install
