#! /bin/bash 
#This script is created by lp  in order to make izone test easily. 
#Set times this test will be conducted, one should adjust this parameter by 
#provided its value  with command line such as "./iozone-performance.sh  num". The default value of it is 3. 
#Not support sh iozone-performance.sh num , dataprocessing1 will fail. 
iotestdir="$LSTSRC/iozone3_430"
iotmpresult="$iotestdir/iozone.log"
ioresult="$LSTRESULT/iozone.csv"
TESTMEM=$(free -m | grep Mem: | awk {'print $2'}) #系统内存 
TESTMEM=$(($TESTMEM / 1024))     
filesize=$(($TESTMEM + 1))    
filesize=$filesize #测试文件为2倍内存 
TESTR=32                    #测试块大小 
TESTS=$filesize              
TESTCPU=$(cat /proc/cpuinfo | grep processor | wc -l) #系统CPU核数 
TESTPARTSIZE=$(($filesize * 3 / 2)) #所需测试磁盘分区大小，测试文件的1.5倍
#标准测试 结果处理 
checkresult(){
TESTSBITE=`echo "$TESTS * 1024 * 1024" | bc`
cat $iotmpresult | grep "$TESTSBITE      $TESTR" | awk '{print $3,$4,$5,$6,$7,$8}' >> $ioresult
}
#标准测试 
exceltest() { 
cd $iotestdir
dat=$(date +%s -d "$time hour")
while :
do
    tim=$(date +%s)
    if [ $tim -lt $dat ];then
        ./iozone -Rb iozone_results_$num.xls  -i 0 -i 1 -i 2 -f $1/iozone_io_$tim.file -r $TESTR -s $TESTS\g | tee -a $iotmpresult
        checkresult
        [ ! -d $iotestdir/result ] &&  mkdir $iotestdir/result
        mv $iotmpresult $iotestdir/result/iozone-$tim.log
        echo 3 > /proc/sys/vm/drop_caches 
    else
        break
    fi
done 
} 
#测试前环境准备
[ -e $iotmpresult ] && rm -f $iotmpresult
[ -e $ioresult ] && rm -f $ioresult
 
if [ ! -x $iotestdir/iozone ];then
    cd $iotestdir
    make linux
fi
time=$2
exceltest $1
