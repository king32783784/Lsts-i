 #!/bin/bash
#This script is created by lp  in order to make check systemclock test easily.
#provided its value  with command line such as "sh Runtest num". Your should enter the right message fllow the help info.
#时钟同步
apptestdir="$LSTSRC/stressapptest-1.0.4_autoconf"
systmpresult="$LSTRESULT/sytemclock.log"
systemclock()
{
ntpdate asia.pool.ntp.org >> $systmpresult
errorno=`echo $?`
while :
do
if [ $errorno -gt 0 ];then
    ntpdate asia.pool.ntp.org >> $systmpresult
    errorno=`echo $?`
else
    break
fi 
done
}
setup()
{
if [ ! -f $apptestdir/src/stressapptest ];then  
    cd $apptestdir
    if which yum >/dev/null 2>&1;then
        yum install -y libaio.x86_64
        yum install -y libaio-devel.x86_64
    fi
    ./configure
    make 
    make install
fi
}
checkresult()
{
    grep offset $systmpresult | awk '{print $10}' > time.cache
    tim=`awk 'NR==2 {print $1}' time.cache`
    tmp1=`echo "$tim > 0" | bc` 
    if [ $tmp1 -eq 0 ];then
	tim=`echo "0 - $tim "| bc`
    fi
    tmp2=`echo "$tim >= 3" | bc `
    if [ $tmp2 -eq 1 ]; then
        echo -e  "\033[31;49;1m Test is  fail,the systemclock offset $tim second after $time hours \033[39;49;0m" | tee -a $systmpresult
    else
	echo -e "\033[32;49;1m Test is pass,the systemclock offset $tim second after $time hours  \033[39;49;0m" | tee -a $systmpresult
    fi
    rm time.cache
}
Before()
{
    echo "Before test" >> $systmpresult
    echo "******Clock synchronization" >> $systmpresult
    systemclock
    hwclock -w 
    echo "*****DATE******" >> $systmpresult
    date >> $systmpresult
    echo "*****Hwclock****" >> $systmpresult
    hwclock >> $systmpresult
}

After()
{
    echo "After test " >> $systmpresult
    echo "*****DATE****" >> $systmpresult
    date >> $systmpresult
    echo "*****Hwclock*** " >> $systmpresult
    hwclock >> $systmpresult
    echo "*****The hardware clock synchronization*****" >> $systmpresult
    hwclock -w >> $systmpresult
    echo "******Clock synchronization" >> $systmpresult
    systemclock
    sleep 3
}

Highload()
{
echo  -e "\033[31;49;1m Highload test start \033[39;49;0m"
echo "High load test result " >> $systmpresult
Before
stressapptest -M 1024M -s $times >> $LSTRESULT/stressapptest.log
After
checkresult
mv $systmpresult $LSTRESULT/sytemclock-high-$(date +'%Y%m%d%H%M').log
sleep 5
}

Idel()
{
echo -e "\033[32;49;1m Idel test start \033[39;49;0m"
echo "Idel test result" >> $systmpresult
Before
sleep $times
After
checkresult
mv $systmpresult  $LSTRESULT/systemclock-idel-$(date +'%Y%m%d%H%M').log
sleep 5
} 

Both()
{
echo -e "\033[32;49;1m Both mode test \033[39;49;0m"
echo  -e "\033[31;49;1m Highload test start \033[39;49;0m"
echo "High load test result " >> $systmpresult
Before
stressapptest -M 1024M -s $times >> $LSTRESULT/stressapptest.log
After
checkresult
mv $systmpresult $LSTRESULT/systemclock-high-$(date +'%Y%m%d%H%M').log
sleep 5
echo -e "\033[31;49;1m Idel test start \033[39;49;0m"
echo "Idel test result" >> $systmpresult
Before
sleep $times
After
checkresult
mv $systmpresult $LSTRESULT/systemclock-idel-$(date +'%Y%m%d%H%M').log
sleep 5
}
setup
[ -e $LSTRESULT/stressapptest.log ] && rm -f $LSTRESULT/stressapptest.log
[ -e $systmpresult ] && rm -f $systmpresult
clockmode="$1"
echo $2
time="$2"
times=$(($time * 36))
echo $times
case $clockmode in
    HL|Hl|hL|hl)
    Highload   
      ;;
    Il|IL|iL|il)
    Idel
      ;;
    ALL|ALl|AlL|All|aLL|alL|all|aLl)
    Both
      ;;
    *)
    echo -e "\033[31;49;1m  Invalid input! Please input again!\033[39;49;0m"
      ;;
    esac
