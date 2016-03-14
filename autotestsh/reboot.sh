#!/bin/bash
date -d "$(awk -F. '{print $1}' /proc/uptime) second ago" +"%Y-%m-%d %H:%M:%S">>/etc/reboot-time.log
setup(){ #增加用户，并且设置为开机自动登录，自动运行脚本
if  grep -a "iSoft Server" /etc/issue > /dev/null
then
    if [ ! -f /etc/reboot.sh ];then
        cp -rf $TESTSHELL/reboot.sh /etc/
    fi
    if grep "reboot.sh" /etc/rc.local > /dev/null;then
	break;
    else
        echo "/bin/sh /etc/reboot.sh &" >> /etc/rc.local
    fi
    if id testuser > /dev/null 2>&1; then
    break
    else
    useradd testuser
    passwd testuser  << EOF 
    abc123
    abc123
EOF
    fi
    if grep AutomaticLogin /etc/gdm/custom.conf > /dev/null;then
    break
    else
    line=`awk '/\[daemon\]/{print NR;exit}' /etc/gdm/custom.conf`
    line=$(($line + 1))
    sed -i "$line a AutomaticLogin=testuser" /etc/gdm/custom.conf 
    line=$(($line + 1))
    sed -i "$line a AutomaticLoginEnable=True" /etc/gdm/custom.conf
    fi
else if grep -a "iSoft Enterprise Desktop" /etc/issue > /dev/null
then
    if [ ! -f /etc/reboot.sh ];then
        cp -rf $TESTSHELL/reboot.sh /etc/
    fi
    if grep "reboot.sh" /etc/profile > /dev/null;
    then
       break;
    else
        echo "/bin/sh /etc/reboot.sh &" >> /etc/profile
    fi
    fi
fi
}
setup
CURDIR=$LSTRESULT
if [ ! -f /etc/tmpbash ];then 
echo $CURDIR >> /etc/tmpbash
echo $1 >> /etc/tmpbash
fi
CURDIR=`cat /etc/tmpbash | head -n 1`
if [ ! -f $CURDIR/reboot.log ]; then
echo " Times=0 , start at `date`" >> $CURDIR/reboot.log
fi
times=`cat /etc/tmpbash | tail -n 1`
n=`cat $CURDIR/reboot.log|awk '{print substr($1,7)}'|tail -1`
while [ $n -lt $times ];do
    n=$(($n + 1))
    echo " Times=$n , reboot at `date`" >> $CURDIR/reboot.log
sleep 60
reboot
done
rm /etc/tmpbash
rm /etc/reboot.sh
