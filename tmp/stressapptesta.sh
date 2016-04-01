#!/bin/bash
#This script is created by LP in order to make  stressapptest stability easily.
#Howto:sh stressapptest-stability ; Please enter right message follow the help info.
[ -e $LSTRESULT/stressapptest.log ] && rm -f $LSTRESULT/stressapptest.log 
setup()
{
    cd $LSTSRC/stressapptest-1.0.4_autoconf
    make clean
    if which yum >/dev/null 2>&1;then
        yum install -y libaio.x86_64
        yum install -y libaio-devel.x86_64
    fi
    ./configure
    make 
    make install
}
#check the memsize of the system
check_memsize()
{      
    PROC_NUM=0
    echo 3 > /proc/sys/vm/drop_caches
    TESTMEM=$(free -m | grep Mem: | awk {'print $4'})
    memsize=$[$TESTMEM*9/10] 
    while [ $memsize -gt 1024 ]   #if greater than 1GB
    do
        PROC_NUM=$(( PROC_NUM + 1 ))
    	memsize=$(( $memsize - 1024 ))
    done
    leftover_memsize=$memsize
}
# test control
do_test()
{

echo 3 > /proc/sys/vm/drop_caches
check_memsize
for((num=0;num < $PROC_NUM; num++))
do	
    echo "NO.$num thread of stressapptest is running"
    stressapptest -M 1024 -s $1 >> $LSTRESULT/stressapptest.log  &
    sleep 1
done

if [ $leftover_memsize -gt 20 ];then
    echo "The last thread of stressapptest is running"
    stressapptest -M $leftover_memsize -s $1 >> $LSTRESULT/stressapptest.log &
    sleep 5
    AFTERTESTMEM=$(free -m | grep Mem: | awk {'print $4'})
    echo "The free memory of system is $AFTERTESTMEM MB NOW!"
    sleep 5
    sleep $1
    checkresults
else
break
fi
}
# check the results
checkresults(){
    grep mis $LSTRESULT/stressapptest.log >> $LSTRESULT/cpu_memtest.log
    if [ $? != 0 ]; then
        echo -e " \033[32;49;1m There is no error in time $tim test log,The test is PASS \033[39;49;0m" | tee -a $LSTRESULT/cpu_memtest.log
    else
        echo -e "\033[31;49;1m There is some error in time $tim test log,please see the messages in errormessage \033[39;49;0m" | tee -a $LSTRESULT/cpu_memtest.log
    fi
	}
#start test
if [ ! -x $LSTSRC/stressapptest-1.0.2_autoconf/src/stressapptest ]; then
setup
fi
times=$1
times=$(($times * 3600))
do_test $times 
