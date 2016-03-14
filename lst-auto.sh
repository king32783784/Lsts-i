#！/bin/bash 
###################################################################################
#This script is created by lp in order to make stress test easily.               ##
#The test set contains :                                                         ## 
#1.Ltpstress:Test the stability of the kernel.                                   ##
#2.Iozone:Stability of test file systems and disk IO.                            ##
#3.Reboot:Test system stability of the hot start.                                ##
#4.Clocktest-idel:Test the stability of the system clock when the system is idle.##
#5.Clocktest-overload:Test system stability of the clock in the system overload. ##
#6.Tftp/wget/scp:Test system stability of network transfer files.                ## 
#7.Datatest:Test system stability of the storage device transfer files.          ##
#8.Netperf:Test the stability of the network.                                    ##
#9.Stressapptest:Test the stability of the CPU and mem.                          ##
#Howto:sh *.sh.                                                                  ##
###################################################################################
export LSTROOT=${PWD}
export LSTRESULT="$LSTROOT/result"
export TESTSHELL="$LSTROOT/autotestsh"
export LSTSRC="$LSTROOT/src"
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
if which expect > /dev/null ;then
   break;
   elif which pacman > /dev/null;then
	pacman -S --noconfirm expect
   elif which yum > /dev/null;then
	yum install -y expect
fi
#检查测试serverIP是否合法
checkip() {
        if [ $# -lt 1 ];then
        echo "IP does not support null"
        fi
        if echo $1 |egrep -q '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' ; then
                a=`echo $1 | awk -F. '{print $1}'`
                b=`echo $1 | awk -F. '{print $2}'`
                c=`echo $1 | awk -F. '{print $3}'`
                d=`echo $1 | awk -F. '{print $4}'`

                for n in $a $b $c $d; do
                        if [ $n -ge 255 ] || [ $n -le 0 ]; then
                                echo 'bad ip(2)!'
                                return 2
                        fi
                done
        else
                echo 'bad ip(1)!'
                return 1
        fi
}
#指定测试serverIP
setserverIP()
{
echo -n "Please enter Server IP:"
read IP
checkip $IP
returnno=`echo $?`
while :
do
if [ $returnno -gt 0 ];then
    echo -n "Please enter Server IP:"
    read IP
    checkip $IP
    returnno=`echo $?`
else
    break
fi
done
}
#设定测试时间
settime()
{
     AGAIN=Y
     while [ $AGAIN = Y ]
     do
     echo  -e "\033[33;49;1m Please enter test time(hours)[default 12] \033[39;49;0m"
        read time
        if [ "X$time" != X ]
        then    case "$time" in
                [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
                        break
                        ;;
                *)      echo "Please enter a number between 1 and 999"
                        AGAIN=Y
                        ;;
                esac
        else    AGAIN=N
                time=12
        fi
     done
     #echo $time
}
settimes()
{
     AGAIN=Y
     while [ $AGAIN = Y ]
     do
     echo  -e "\033[33;49;1m Please enter test times[default 100] \033[39;49;0m"
        read times
        if [ "X$times" != X ]
        then    case "$times" in
                [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
                        break
                        ;;
                *)      echo "Please enter a number between 1 and 99999"
                        AGAIN=Y
                        ;;
                esac    
        else    AGAIN=N 
                times=100
        fi      
     done
    # echo $times
}
#设定测试文件大小
#检查设定dd参数是否合法
checkcount() {
        if [ $# -lt 1 ];then
                COUNT=4
                return 0
        else
        echo $1 | grep "[^0-9]" >> /dev/null && return 1 || return 0
        fi
}
#指定测试文件的大小
setsize()
{
    echo -e "\033[32;49;1m Please enter testfile size (GB) and the number of small files(K),Its must be a Natural number,like\"1-100\"):  \033[39;49;0m"
    read COUNT
    checkcount $COUNT
    returnno=`echo $?`
    while :
        do
        if [ $returnno -gt 0 ]; then
            echo -e "\033[31;49;1m  Enter test file size again: \033[39;49;0m"
            read COUNT
            checkcount $COUNT
            returnno=`echo $?`
        else
            break
        fi
    done
    COUNTA=$(($COUNT * 1024))
}
#调用测试对应脚本，执行测试
datatest()
{
   sh  $TESTSHELL/datatesta.sh $datacount $datatimes ${datatestpart[0]} ${datatestpart[1]}
}
ltptest()
{
    sh $TESTSHELL/ltpa.sh $ltptime
}
clocktest()
{
    sh $TESTSHELL/clocka.sh $clockmode $clocktimes
}
iotest()
{
    cd $TESTSHELL
    #echo $iono
    for ((m=0; m<$iono;m++))
    do
       ./iozonea.sh ${iotestpart[$m]} $iotimes
    done
}
reboottest()
{
    sh $TESTSHELL/reboot.sh $rttimes
}
nettest()
{
    if [ ! -f $LSTSRC/netperf-2.6.0/src/netperf ];then
	cd $LSTSRC/netperf-2.6.0
	./configure
	make
	make install
    fi
    sh $TESTSHELL/netperfa.sh $nettime $netip
}
tftptest()
{
    if which tftp > /dev/null ;then
    :
    elif which pacman > /dev/null;then
        pacman -S --noconfirm tftp-hpa
    elif which yum > /dev/null;then
        yum install -y tftp
    fi
    sh $TESTSHELL/tftpa.sh $tpcount $tptime $tpip
}
scptest()
{
    sh $TESTSHELL/scpa.sh $sptime $spcount $spip
}	
wgettest()
{
    sh $TESTSHELL/wgeta.sh $wttime $wtcount $wtip
}
sttest()
{
   sh $TESTSHELL/stressapptesta.sh $sttime
}
#系统时钟测试参数读入
clocksetup()
{
while :
do
    cat<<EOF
                     System clock stability test
  _______________________________________________________________
                 HL:Clcok test when the system is in a State of high load
                 IL:Clock test when the system is in a State of idel
                 ALL:Clock test when the system is in a State of idel ande high load
  _______________________________________________________________
EOF
     echo -e "\033[32;49;1m Which mode do you want to test? \033[39;49;0m"
    read CLOCKCHOICE
    case $CLOCKCHOICE in
    HL|Hl|hL|hl)
    clockmode="$CLOCKCHOICE"
    settime
    clocktimes=$time
    break
      ;;
    Il|IL|iL|il)
    clockmode="$CLOCKCHOICE"
    settime
    clocktimes=$time
    break
      ;;
    ALL|ALl|AlL|All|aLL|alL|all|aLl)
    clockmode="$CLOCKCHOICE"
    settime
    clocktimes=$time
    break
      ;;
    *)
    echo -e "\033[31;49;1m  Invalid input! Please input again!\033[39;49;0m"
      ;;
    esac
done
} 
#iozone 测试参数读入

ioset()
{
TESTMEM=$(free -m | grep Mem: | awk {'print $2'}) #系统内存
TESTMEM=$(($TESTMEM / 1024))
filesize=$(($TESTMEM + 1))
filesize=$filesize #测试文件为2倍内存
export TESTR=32                    #测试块大小
TESTS=$filesize
TESTCPU=$(cat /proc/cpuinfo | grep processor | wc -l) #系统CPU核数
export TESTPARTSIZE=$(($filesize * 3 / 2)) #所需测试磁盘分区大小，测试文件的1.5倍
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
    cat<<EOF
                     IOZONE stability test
  _________________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _________________________________________________________________
  Iozone tests,you should enter the  partition number,such as sda1,
  sdb1...You can also enter more than one test partition,such
  as "sda1 sda2 sdb1"(Must be a space as the interval).
  _________________________________________________________________
EOF
    echo -e "\033[32;49;1m Please enter the partition number ? \033[39;49;0m"
    read -a IOCHOICE
    iono=${#IOCHOICE[@]}
    for ((k=0;k<$iono;k++))
    do
        lsblk | awk '$6=="part" {print $1}' | tr -d "├─" | grep -w ${IOCHOICE[$k]} > /dev/null #测试输入分区是否存在
        noreturn=`echo $?`
        if [ $noreturn -ne 0 ];then
            
            echo -e "\033[31;49;1m The $k of enter is error,there is no ${IOCHOICE[$k]} in this system!\033[39;49;0m"
            exit 0
        fi
        localpart=`lsblk | awk '$7=="/"{print $1}' | tr -d ├─`
        if [ "${IOCHOICE[$k]}" = "$localpart" ];then
            partfreetype=`df -h /dev/${IOCHOICE[$k]} | tail -1 | awk '{print $4}' | tr -d [0-9]`
             if [ "$partfreetype" != "G" ];then
                echo -e "\033[31;49;1m There is no enough space of the $k partition for test!please check it!\033[39;49;0m"
                exit 0
            fi
            localfreesize=`df -h /dev/${IOCHOICE[$k]} | tail -1 | awk '{print $4}' | tr -d "G"`   #测试输入分区容量是否满足测试
            TMP1=`echo "$localfreesize > $TESTPARTSIZE" | bc `
            if [ $TMP1 -eq 0 ];then
                echo -e "\033[31;49;1m There is no enough space of the $k partition for test!please check it!\033[39;49;0m"
            exit 0
            else
                iotestpart[$k]="/mnt"
            fi
        else
            [ ! -f /mnt/iotest$k ] && mkdir  /mnt/iotest$k
            mount /dev/${IOCHOICE[$k]} /mnt/iotest$k
            partfreetype=`df -h /mnt/iotest$k | tail -1 | awk '{print $4}' | tr -d [0-9]`
            if [ "$partfreetype" != "G" ];then
                echo -e "\033[31;49;1m There is no enough space of the $k partition for test!please check it!\033[39;49;0m"
                exit 0
            fi
            partfreesize=`df -h /mnt/iotest$k | tail -1 | awk '{print $4}' | tr -d "G"`
            TMP2=`echo "$partfreesize > $TESTPARTSIZE" | bc `
            if [ $TMP2 -eq 0 ];then
                echo -e "\033[31;49;1m There is no enough space of the $k partition for test!please check it!\033[39;49;0m"
                exit 0
            else
                iotestpart[$k]="/mnt/iotest$k"
            fi
        fi
    done
    settime
    iotimes=$time
}
#data transfer test 参数读入
datasetup()
{
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
    cat<<EOF
                     Data transfer stability test
  _____________________________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _____________________________________________________________________________
  By CP to transfer files between two partitions,and verify that the file is 
  transferred correctly.
  1.Need to specify the size of the test file.scch as 4GB.
  2.Need to enter two partition number,such as sda1 sdb1，sda1 sda2(Must be
   a space as the interval).
  _______________________________________________________________
EOF
    setsize
    datacount=$COUNTA
    echo -e "\033[32;49;1m Please enter the partition number ?such as "sda1 sdb1" \033[39;49;0m"
    read -a DATACHOICE
    datano=${#DATACHOICE[@]}
    for ((l=0;l<$datano;l++))
    do
        lsblk | awk '$6=="part"|| $6=="disk" {print $1}' | tr -d "├─" | grep -w ${DATACHOICE[$l]} > /dev/null #测试输入分区是否存在
        noreturn=`echo $?`
        if [ $noreturn -ne 0 ];then
            echo -e "\033[31;49;1m The $l of enter is error,there is no ${DATACHOICE[$l]} in this system!\033[39;49;0m"
            exit 0
        fi
        localpart=`lsblk | awk '$7=="/"{print $1}' | tr -d ├─`
        if [ "${DATACHOICE[$l]}" = "$localpart" ];then
            localfreesize=`df -h /dev/${DATACHOICE[$l]} | tail -1 | awk '{print $4}' | tr -d "G"`   #测试输入分区容量是否满足测试
            TMP1=`echo "$localfreesize > $COUNT" | bc `
            if [ $TMP1 -eq 0 ];then
                echo -e "\033[31;49;1m There is no enough space of the $l partition for test!please check it!\033[39;49;0m"
            exit 0
            else
                datatestpart[$l]="/mnt"
            fi
        else
            [ ! -f /mnt/datatest$l ] && mkdir  /mnt/datatest$l
            mount /dev/${DATACHOICE[$l]} /mnt/datatest$l
            partfreesize=`df -h /mnt/datatest$l | tail -1 | awk '{print $4}' | tr -d "G"`
            TMP2=`echo "$partfreesize > $COUNT" | bc `
            if [ $TMP2 -eq 0 ];then
                echo -e "\033[31;49;1m There is no enough space of the $l partition for test!please check it!\033[39;49;0m"
                exit 0
            else
                datatestpart[$l]="/mnt/datatest$l"
            fi
        fi
    done
    settime
    datatimes=$time
}
ltpsetup()
{
cat<<EOF
                     Linux test project stress test
  _______________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _______________________________________________________________
EOF
settime
ltptime=$time
}
netsetup()
{
cat<<EOF
                     Network stability  test
  _______________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE 
  _______________________________________________________________
  By netperf to test network stability.
  1.Need to specify the netserver IP
  2.Need to input test time(hours)
  _______________________________________________________________
EOF
 setserverIP
 netip=$IP
 settime 
 nettime=$time
}
stsetup()
{
cat<<EOF
                     CPU and MEM overload stability test
  _______________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _______________________________________________________________
  By stressapptest to test CPU and MEM stability
  1.Need to input test time(hours)
  _______________________________________________________________
EOF
settime
sttime=$time
}
tftpset()
{
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
    cat<<EOF
                     Tftp  stability test
  _____________________________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _____________________________________________________________________________
  By tftp to transfer files between two system,and verify that the file is
  transferred correctly.
  1.Need to specify the size of the test file.scch as 4GB.
  2.Need to input testtime(hours)
  3.Need to input serverip.
  _______________________________________________________________
EOF
 setsize
 tpcount=$COUNTA
 settime
 tptime=$time
 setserverIP
 tpip=$IP
}
wgetset()
{
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
    cat<<EOF
                     Wget  stability test
  _____________________________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _____________________________________________________________________________
  By wget to transfer files between two system,and verify that the file is
  transferred correctly.
  1.Need to specify the size of the test file.scch as 4GB.
  2.Need to input testtime(hours)
  3.Need to input serverip.
  _______________________________________________________________
EOF
 setsize
 wtcount=$COUNTA
 settime
 wttime=$time
 setserverIP
 wtip=$IP
}
scpset()
{
MYDATE=`date +%d/%m/%Y`
THIS_HOST=`hostname`
USER=`whoami`
    cat<<EOF
                     Scp  stability test
  _____________________________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _____________________________________________________________________________
  By scp to transfer files between two system,and verify that the file is
  transferred correctly.
  1.Need to specify the size of the test file.scch as 4GB.
  2.Need to input testtime(hours)
  3.Need to input serverip.
  _______________________________________________________________
EOF
 setsize
 spcount=$COUNTA
 settime
 sptime=$time
 setserverIP
 spip=$IP
}
rebootset()
{
cat<<EOF
                     Warmboot stability test
  _______________________________________________________________
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE
  _______________________________________________________________
  By stressapptest to test CPU and MEM stability
  1.Need to input test time
  _______________________________________________________________
EOF
settimes
rttimes=$times
}
#测试项目选择
while : 
do
    clear
    cat<<EOF 
                     L i n u x  s t a b i l i t y  t e s t 
  _______________________________________________________________ 
  User:$USER        Host:$THIS_HOST          DATE:$MYDATE 
  _______________________________________________________________ 
                 LTP:ltpstress test (kernel stability test)
                 IO:iozone test  (File system stability test)
                 RB:reboot tets  
                 SC:sytem clock test
                 DT:data transfer test  (Transfer files by SATA and USB)
                 NP:netperf test  (Network stability test)
                 ST:stressapptest (CPU and MEM stability test)
                 TP:tftp transfer test (Transfer files by tftp)
                 SP:scp transfer test (Transfer files by scp)
                 WT:wget transfer test (Transfer files by wget)
                 ALL:All of this test
  _______________________________________________________________ 
EOF
    echo -e "\033[32;49;1m Which item do you want to test? \033[39;49;0m"
    echo -e "\033[32;49;1m You should enter the item,such as \"LTP\",\"IO\". You can also enter more than one test item,such
as "LTP IO RB SC"(1.Must be a space as the interval 2.Reboot must be placed in the last).\033[39;49;0m" 
    read -a CHOICE
    no=${#CHOICE[@]}  #读入测试项目
    for ((i=0;i<$no;i++)) #检查输入的测试项目是否正确
    do
    echo "${CHOICE[$i]}" | egrep -w '[Ll][Tt][Pp]|[Ii][Oo]|[Rr][Bb]|[Ss][Cc]|[Tt][Pp]|[Ss][Pp]|[Ww][Tt]|[Dd][Tt]|[Nn][Pp]|[Ss][Tt]|[Aa][Ll][Ll]' 
    returnno=`echo $?`
    if [ $returnno -ne 0 ];then
	echo "Invalid input,please check it "
        exit 0
    fi
    done
    no1=$no
    for ((i=0;i<$no1;i++))    #为选择的测试项目，轮询设定测试参数
    do  
	choice="${CHOICE[$i]}"
	case $choice in
             LTP|ltp|Ltp|LtP|lTP|lTp|LTp|ltP)
             ltpsetup
             ;;
             IO|io|iO|Io)
             ioset
             ;;
             RB|Rb|rb|rB)
             rebootset
             ;;
             SC|Sc|sc|sC)
             clocksetup
             ;;
             DT|Dt|dT|dt)
             datasetup
             ;;
             NP|np|Np|nP)
             netsetup
             ;;
             TP|Tp|tP|tp)
             tftpset
	     ;;
             WT|Wt|wT|wt)
             wgetset
             ;;
             SP|Sp|sP|sp)
             scpset
             ;;
             ST|St|sT|st)
             stsetup
             ;;
             ALL|ALl|AlL|All|aLl|aLL|alL|all)
             ltpsetup
             ioset
    	     clocksetup
	     datasetup
             netsetup
             tftpset
             wgetset
             scpset
             stsetup
             rebootset
             ;;  
             esac
     done
    no2=$no
    for ((j=0;j<$no2;j++))  #按照输入的项目列表，进行轮询测试
    do   
        choice="${CHOICE[$j]}"
        case $choice in
             LTP|ltp|Ltp|LtP|lTP|lTp|LTp|ltP)
             ltptest
             ;;
             IO|io|iO|Io)
             iotest
             ;;
             RB|Rb|rb|rB)
             reboottest
             ;;
             SC|Sc|sc|sC)
             clocktest
             ;;
             DT|Dt|dT|dt)
             datatest
             ;;
             NP|np|Np|nP)
             nettest
             ;;
             WT|Wt|wt|wT)
             wgettest
             ;;
             SP|Sp|sP|sp)
             scptest
             ;;
             TP|Tp|tP|tp)
             tftptest
             ;;
             ST|St|sT|st)
             sttest
             ;;
             ALL|AlL|ALl|All|aLL|aLl|alL|all)
             iotest
             clocktest
             ltptest
             datatest
             nettest
             wgettest
             tftptest
             scptest
             sttest
             reboottest
             ;;
             esac
     done
     exit 0
done
