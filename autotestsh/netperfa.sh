#!/bin/bash
#This script is created by LP in order to test the netperf performance easily.
#Howto:sh netperf-performance ; Please enter right message follow the help info.
#Test result file:netperf-result.csv
#Environment initialization
IP=$2
env_init()
{
    echo 3 > /proc/sys/vm/drop_caches
    sleep 3s
}
serversetup()
{
expect <<EOF
spawn scp -r /home/stability-testtool/src/netperf-2.6.0 root@$IP:/home/
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect eof
EOF
expect <<EOF
set timeout -1
spawn ssh root@$IP
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect  "]# "
send "cd /home/netperf-2.6.0\r"
send "./configure\r"
send "make\r"
send "make install\r"
send "netserver\r"
#send "service  iptables stop\r"
send " if grep -q Server /etc/issue;then service iptables stop ;else systemctl stop firewalld.service;fi\r"
send "exit\r"
expect eof
exit
EOF
}
stability_test()
{
    times=$1
    ip=$2
    serversetup
    time=10
    num=1
    while  [ "$num" -le $times ]; do
        env_init
        netperf -f M -H $ip  -l $time -t TCP_STREAM | tee -a $LSTRESULT/netperf-stability.log
    num=$(($num + 1))
    sleep 3
    done
    cat $LSTRESULT/netperf-stability.log | grep 87380  | awk '{print $5}' | sort > $LSTRESULT/netperf.cache
    tmpnum=`cat $LSTRESULT/netperf.cache | wc -l`
    if [ $tmpnum -ne $times ]; then
        echo -e "\033[31;49;1m Test interruption,only $tmpnum times! \033[39;49;0m"
    else
        tmp=0
        for ((i=1;i<=$tmpnum;i++))
            do
                num1=`sed -n "$i p" $LSTRESULT/netperf.cache`
                tmp=`echo "$tmp + $num1" | bc `
            done
	echo $tmp
        littlenum=`sed -n "1 p" $LSTRESULT/netperf.cache`
        largenum=`sed -n "$times p" $LSTRESULT/netperf.cache`
        midnum=`echo " scale=2;$tmp / $times" | bc`
        pernum=`echo "scale=2; (125 - $midnum) / 1.25 " | bc`
        clear
        echo -e "\033[32;49;1m Network stability test result \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Card rate: $times \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Sampling interval: $time seconds \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Average transfer rate: $midnum MB/sec \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Lower then Gigabit network theory: $pernum% \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Maximum value: $largenum MB/sec \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
        echo -e "\033[32;49;1m Min value:$littlenum MB/sec \033[39;49;0m" | tee -a $LSTRESULT/netperf-stability-result.log
    fi
    mv $LSTRESULT/netperf-stability.log $LSTRESULT/netperf-stability-$(date +'%Y%m%d%H%M').log
    rm $LSTRESULT/netperf.cache
}
testtime=$(($1 * 6))
stability_test $testtime $2
