#! /bin/bash 
#This script is created by lp  in order to make ltpstress test easily. 
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
rshfile="/etc/pam.d/rsh"
rloginfile="/etc/pam.d/rlogin"
ltpresultdir="$LSTRESULT/ltp"
ltpresult="ltp-result.csv"
echo $LSTSRC
serversetup()
{
#解压安装LTP
    if [ ! -d /opt/ltp ];then
	    LTPDIR=`ls $LSTSRC | grep "ltp" | grep -v -e "tar" -e "bz2" -e "gz" -e "zip"`
	    echo $LTPDIR
	    echo $LSTSRC/$LTPDIR
	    cd $LSTSRC/$LTPDIR
	    ./configure
	    make 
	    make install
    fi
#解压安装sar工具
    which sar > /dev/null
    returnno1=`echo $?`
    if [ $returnno1 -ne 0 ];then
	    SARDIR=`ls $LSTSRC | grep "sysstat" | grep -v -e "tar" -e "bz2" -e "gz" -e "zip"`
	    cd $LSTSRC/$SARDIR
	    ./configure
    	    make
    	    make install
   fi
#关闭selinux和firewall
    setenforce 0
    service iptables stop
#编辑/etc/hosts文件，添加：<本机IP> <主机名>
    IPNUM=`ifconfig -a | grep -w inet | grep -v 127.0.0.1 | awk '{print $2}'|tr -d "addr:" | tr -d "地址" | wc -l`
    if [ $IPNUM -le 0 ];then
        echo -e "\033[31;49;1m No available IP,please check it!\033[39;49;0m"
    else
        TMPNU=1
        while [ $TMPNU -le $IPNUM ];do
            TMPIP=`ifconfig -a | grep -w inet | grep -v 127.0.0.1 | awk '{print $2}'|tr -d "addr:" | tr -d "地址" | sed -n " $TMPNU p"`
            ping $TMPIP -c 1 >/dev/null
            returnno2=`echo $?`
            if [ $returnno2 -eq 0 ];then
                SYSIP=$TMPIP
                break
            else
                TMPNU=$(($TMPNU + 1 ))
            fi
        done
        if [ $TMPNU -gt $IPNUM ];then
            echo -e "\033[31;49;1m No available IP,please check it!\033[39;49;0m"
        fi
    fi
    HOSTNAME=`hostname`
    echo "$TMPIP $HOSTNAME" >>/etc/hosts
#编辑/etc/securetty文件，添加rsh项和rlogin项两行
    echo "rsh" >> /etc/securetty
    echo "rlogin" >> /etc/securetty
#编辑/etc/pam.d/rsh和/etc/pam.d/rlogin文件，注销"auth required pam_securetty.so"行
if [ ! -f $rshfile ];then
    yum install -y rsh
    yum install -y rsh-server
fi       
    sed -i 's/\(auth       required     pam_securetty.so\)/#auth       required     pam_securetty.so/' $rshfile
    sed -i 's/\(auth       required     pam_securetty.so\)/#auth       required     pam_securetty.so/' $rloginfile
#在root目录下建立.rhosts    
    echo "127.0.0.1" >> /root/.rhosts
    echo "localhost" >> /root/.rhosts
    echo "$HOSTNAME" >> /root/.rhosts
    echo "$HOSTNAME" >> /root/.rhosts
#编辑/etc/xinetd.d/rsh与/etc/xinetd.d/rlogin文件，将配置文件中的yes项改成no
    sed -i 's/yes/no/' /etc/xinetd.d/rsh
    sed -i 's/yes/no/' /etc/xinetd.d/rlogin
#重新启动xinetd服务
    service xinetd restart
    chkconfig xinetd on
#建立一个存放结果的目录
    ltpstarttim=`date +%d/%m/%Y`
    [ -d $ltpresultdir ] && rm -rf $ltpresultdir
    mkdir -p $ltpresultdir
#修改 ltpstress.sh
    sed -i 's/\( sar -o $datafile $interval 0 &\)/sar -o $datafile $interval \&/' /opt/ltp/testscripts/ltpstress.sh 
}
clientsetup()
{
 runsrc="/opt/ltp"
  if [ ! -d /opt/ltp ];then
            LTPDIR=`ls $LSTSRC | grep "ltp" | grep -v -e "tar" -e "bz2" -e "gz" -e "zip"`
            echo $LTPDIR
            echo $LSTSRC/$LTPDIR
            cd $LSTSRC/$LTPDIR
            ./configure
            make
            make install
    fi
#解压安装sar工具
    which sar > /dev/null
    returnno1=`echo $?` 
    if [ $returnno1 -ne 0 ];then 
            SARDIR=`ls $LSTSRC | grep "sysstat" | grep -v -e "tar" -e "bz2" -e "gz" -e "zip"`
            cd $LSTSRC/$SARDIR
            ./configure
            make 
            make install
   fi
systemctl disable firewalld.service
cp $LSTSRC/ltp-full-20140115/isoft-client/ltpstress.sh  $runsrc/testscripts/ltpstress.sh 
sed -i 's/^nfs01/#nfs01/' $runsrc/runtest/stress.part1
sed -i 's/^nfs02/#nfs02/' $runsrc/runtest/stress.part1
sed -i 's/^nfs03/#nfs03/' $runsrc/runtest/stress.part1
sed -i 's/^nfs04/#nfs04/' $runsrc/runtest/stress.part1
sed -i 's/^nfsstress/#nfsstress/' $runsrc/runtest/stress.part1
sed -i 's/^nfsx-linux/#nfsx-linux/' $runsrc/runtest/stress.part1
sed -i 's/DEVICE/$DEVICE/' $runsrc/runtest/stress.part3
sed -i 's/DEVICE_FS_TYPE/$DEVICE_FS_TYPE/' $runsrc/runtest/stress.part3
sed -i 's/^rpc01/#rpc01/' $runsrc/runtest/stress.part3
sed -i 's/^run_rpc_tests.sh/#run_rpc_tests.sh/' $runsrc/runtest/stress.part3
#建立一个存放结果的目录
ltpstarttim=`date +%d/%m/%Y`
[ -d $ltpresultdir ] && rm -rf $ltpresultdir
mkdir -p $ltpresultdir
}
	
#启动测试
server_dotest()
{
    cd /opt/ltp/testscripts/
    /opt/ltp/testscripts/ltpstress.sh -d $ltpresultdir/sar.out -l $ltpresultdir/ltpstress.log -t $1 -S >$ltpresultdir/ltpstress-result &
    check_test
}
client_dotest()
{   cd /opt/ltp/testscripts/
    /opt/ltp/testscripts/ltpstress.sh -d $ltpresultdir/sar.out -l $ltpresultdir/ltpstress.log -t $1 -n -S >$ltpresultdir/ltpstress-result &
    check_test
}
#测试环境恢复
envinit()
{
    killall -9 ltpstress.sh > /dev/null 2>&1
    killall -9 sh >/dev/null 2>&1
    killall -9 sadc >/dev/null 2>&1
    killall -9 ltp-pan >/dev/null 2>&1
    killall -9 genload >/dev/null 2>&1
    killall -9 sleep > /dev/null 2>&1
#    killall -9 netpipe.sh >/dev/null 2>&1
#    killall -9 NPtcp >/dev/null 2>&1
    rm -rf /tmp/*
}
check_test()
{ 
    for ((i=0;i<$testtime;i++))
    do	
        sleep 3600
	cd $ltpresultdir
        interval=`stat -c %Y ltpstress.log |awk '{printf  $0" "; system("date +%s")}'|awk '{print $2-$1}'`
	echo $interval
        if [ "$interval" -gt 600 ];then
	    envinit
            do_test
        fi
    done                    
}      
Resultsorting()
{   
    cd $ltpresultdir
    [ ! -d $ltpresult ] && rm -rf $ltpresult
    PASSNUM=`grep PASS ltpstress.log | wc -l`
    FAILNUM=`grep FAIL ltpstress.log | wc -l`
    FAILED=`grep FAIL ltpstress.log |sort|uniq| wc -l`
    TOTALNUM=`echo "$PASSNUM + $FAILNUM " | bc `
    EFFICIENCY=`echo "$TOTALNUM / $testtime" | bc `
    RATETMP=`echo " scale=4;$PASSNUM / $TOTALNUM" | bc `
    RATE=`echo "scale=2;$RATETMP * 100 / 1 "|bc `
    echo "This test results" >> $ltpresult
    echo "Total hours of this test: $testtime" >> $ltpresult
    echo "Total number of tests case: $TOTALNUM " >> $ltpresult
    echo "Case efficiency (cases/hour):$EFFICIENCY" >> $ltpresult
    echo "Total number of tests PASS case: $PASSNUM" >> $ltpresult
    echo "Success rate:$RATE%" >> $ltpresult
    echo "Total number of tests FAIL case: $FAILNUM" >> $ltpresult
    echo "Test FAIL case number: $FAILED" >> $ltpresult
    echo "The FAIL case status: " >> $ltpresult
    printf "Casename%16s Total-num%16s Fail-num%16s\n">> $ltpresult
    num=1
    while [ $num -le $FAILED ];do
        FAILCASE=`grep FAIL ltpstress.log |sort|uniq | sed -n "$num p" | awk '{print $1}'`
        FAILCASENUM1=`grep -w "$FAILCASE" ltpstress.log | wc -l `
        FAILCASENUM2=`grep -w "$FAILCASE" ltpstress.log | grep FAIL | wc -l`
        printf "%-20s %10d %24d\n" $FAILCASE $FAILCASENUM1 $FAILCASENUM2 >> $ltpresult
        num=$(($num + 1))
    done  
    CPULOAD=`echo "100 - $(sar -u -f sar.out  | tail -1 | awk '{print $8}')" | bc`
    MEMLOAD=`sar -r -f sar.out | tail -1 | awk '{print $4}'`
    SWAPLOAD=`sar -S -f sar.out | tail -1 | awk '{print $4}'`
    Ldavg1=`sar -q -f sar.out | tail -1 | awk '{print $4}'`
    Ldavg5=`sar -q -f sar.out | tail -1 | awk '{print $5}'`
    Ldavg15=`sar -q -f sar.out | tail -1 | awk '{print $6}'`
    echo "This test system load conditions" >> $ltpresult
    echo "Average CPU utilization: $CPULOAD%" >> $ltpresult
    echo "Average MEM utilization: $MEMLOAD%" >> $ltpresult
    echo "Average SWAP utilization: $SWAPLOAD%" >> $ltpresult
    echo "Average Ldavg-1 : $Ldavg1% " >> $ltpresult
    echo "Average Ldavg-5 : $Ldavg5% " >> $ltpresult
    echo "Average Ldavg-15: $Ldavg15% " >> $ltpresult
    mv $ltpresultdir/$ltpresult ltp-result-$ltpstarttim.csv
}
testtime=$1
if grep -a "iSoft Client" /etc/issue >/dev/null 
then
clientsetup
client_dotest $testtime
fi
if grep -a "iSoft Server" /etc/issue  >/dev/null
then
serversetup
server_dotest $testtime
fi
Resultsorting
