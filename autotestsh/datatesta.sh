#! /bin/bash
#This script is created by lp  in order to make Data transfer stability test easily.
#Set time this test will be conducted, one should adjust this parameter follow the help info.
#provided its value  with command line such as "./datatest.sh". The default value of it is 3.
tmpdir="$LSTROOT/cptmp"
COUNTA=$1
[ ! -d $tmpdir ] && mkdir $tmpdir
#测试文件准备
prefile()
{
[ -f $tmpdir/bigfile ] && rm -rf $tmpdir/bigfile
[ -f $tmpdir/bigfile.md5sum ] && rm -rf $tmpdir/bigfile.md5
[ -f $tmpdir/littlefile ] && rm -rf $tmpdir/littlefile
[ -f $tmpdir/littlefile.md5sum ] && rm -rf $tmpdir/littlefile.md5sum
echo -e "\033[32;49;1m  "Make test file start" \033[39;49;0m"
dd if=/dev/zero of=$tmpdir/bigfile bs=1M count=$COUNTA   >/dev/null 2>&1                            #创建测试大文件
mkdir  $tmpdir/littlefile
num=1
while [ "$num" -le $COUNTA ]; do                                                #创建测试小文件
    dd if=/dev/zero of=$tmpdir/littlefile/$num bs=1k count=1024 >/dev/null 2>&1
    num=$(($num + 1))
done
echo 3 >/proc/sys/vm/drop_caches
tar cf $tmpdir/littlefile.tar $tmpdir/littlefile >/dev/null 2>&1
echo 3 >/proc/sys/vm/drop_caches
rm -rf $tmpdir/littlefile
mv $tmpdir/littlefile.tar $tmpdir/littlefile
sync
md5sum $tmpdir/bigfile > $tmpdir/bigfile.md5
md5sum $tmpdir/littlefile > $tmpdir/littlefile.md5
echo -e "\033[32;49;1m Make test file  successfully!\033[39;49;0m"
}
#测试环境初始化
#参数：主分区和其他分区
dotest()   
{
test1_file=bigfile      #指定测试文件及临时文件名
test2_file=littlefile      
test1_tmp_file=testfile1
test2_tmp_file=testfile2

test1_md5=bigfile.md5   #指定测试文件及临时文件md5
test2_md5=littlefile.md5
test1_tmp_md5=test1md5
test2_tmp_md5=test2md5

test1_mount=$2    #传入参数，指定测试分区
test2_mount=$3
if [ ! -f $test1_mount/$test1_file ];then
    cp $tmpdir/$test1_file $test1_mount
fi
if [ ! -f $test1_mount/$test1_md5 ];then
    cp $tmpdir/$test1_md5 $test1_mount
fi
if [ ! -f $test1_mount/$test2_file ];then
    cp $tmpdir/$test2_file $test1_mount
fi
if [ ! -f $test1_mount/$test2_md5 ];then
    cp $tmpdir/$test2_md5 $test1_mount
fi    
if [ ! -f $test2_mount/$test1_file ];then
    cp $tmpdir/$test1_file $test2_mount
fi
if [ ! -f $test2_mount/$test1_md5 ];then
    cp $tmpdir/$test1_md5 $test2_mount
fi
if [ ! -f $test2_mount/$test2_file ];then
    cp $tmpdir/$test2_file $test2_mount
fi
if [ ! -f $test2_mount/$test2_md5 ];then
    cp $tmpdir/$test2_md5 $test2_mount
fi
dat=$(date +%s -d "$1 hour")
while :
do
tim=$(date +%s)
if [ $tim -lt $dat ];then
    #从第一分区复制大文件到第二分区并校验
    cp $test1_mount/$test1_file $test2_mount/$test1_tmp_file
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Copying a large file from the first partition to the second partition failed \033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
        echo -e "\033[33;49;1m Copying a large file from the first partition to the second partition successfully \033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
    md5sum $test2_mount/$test1_tmp_file > $test2_mount/$test1_tmp_md5
    tmpAm=`cat $test1_mount/$test1_md5 | awk '{print $1}'` 
    tmpCm=`cat $test2_mount/$test1_tmp_md5 | awk '{print $1}'`
    if [ "$tmpAm" != "$tmpCm" ]; then
        echo -e "\033[31;49;1m The large files verification failed！\033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else 
        echo -e "\033[33;49;1m The large files verification successfully\033[39;49;0m" | tee -a $LSTRESULT/datatest.log

    fi
    
    #从第二分区复制小文件到第一分区并校验
    cp $test2_mount/$test2_file $test1_mount/$test2_tmp_file
    if [ $? != 0 ]; then
       echo -e "\033[31;49;1m Copying small files from the second partition to the frist partition failed\033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
       echo -e "\033[33;49;1m Copying small files from the second partition to the frist partition successfully\033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
    md5sum $test1_mount/$test2_tmp_file > $test1_mount/$test2_tmp_md5
    tmpBm=`cat $test1_mount/$test2_tmp_md5 | awk '{print $1}'`
    tmpDm=`cat $test2_mount/$test2_md5 | awk '{print $1}'`
    if [ "$tmpBm" != "$tmpDm" ]; then
       echo -e "\033[31;49;1m The small files verification failed! \033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
       echo -e "\033[33;49;1m The small files verification successfully! \033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
       
    #从第二分区复制大文件到第一分区并校验
    cp $test2_mount/$test1_file $test1_mount/$test1_tmp_file
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Copying large file from the second partition to the frist partition failed! \033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
        echo -e "\033[33;49;1m Copying large file from the second partition to the frist partition successfully!\033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
    md5sum $test1_mount/$test1_tmp_file > $test1_mount/$test1_tmp_md5
    tmpBm=`cat $test1_mount/$test1_tmp_md5  | awk '{print $1}'`
    tmpCm=`cat $test2_mount/$test1_md5 | awk '{print $1}'`
    if [ "$tmpBm" != "$tmpCm" ]; then
        echo -e "\033[31;49;1m The large files verification failed! \033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
        echo -e "\033[33;49;1m The large files verification successfully! \033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi

    #从第一分区复制小文件到第二分区并校验
    cp $test1_mount/$test2_file  $test2_mount/$test2_tmp_file
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Copying small files from the first partition to the second partition failed!\033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
        echo -e "\033[33;49;1m Copying small files from the first partition to the second partition successfully\033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
    md5sum $test2_mount/$test2_tmp_file > $test2_mount/$test2_tmp_md5

    tmpAm=`cat $test1_mount/$test2_md5 | awk '{print $1}'`
    tmpDm=`cat $test2_mount/$test2_tmp_md5 | awk '{print $1}'`
    if [ "$tmpAm" != "$tmpDm" ]; then
        echo -e "\033[31;49;1m The small files verification failed!\033[39;49;0m" | tee -a $LSTRESULT/datatest-error.log
    else
        echo -e "\033[33;49;1m The small files verification successfully!\033[39;49;0m" | tee -a $LSTRESULT/datatest.log
    fi
    rm -rf $test2_mount/$test1_tmp_file
    rm -rf $test2_mount/$test1_tmp_md5
    rm -rf $test2_mount/$test2_tmp_file
    rm -rf $test2_mount/$test2_tmp_md5
    rm -rf $test1_mount/$test1_tmp_file
    rm -rf $test1_mount/$test1_tmp_md5
    rm -rf $tets1_mount/$test2_tmp_file
    rm -rf $test1_mount/$test2_tmp_md5
    sleep 1
else
   break
fi
done
   rm -rf $test1_mount/$test1_file
   rm -rf $test1_mount/$test2_file
   rm -rf $test1_mount/$test1_md5
   rm -rf $test1_mount/$test2_md5
   rm -rf $test2_mount/$test1_file
   rm -rf $test2_mount/$test2_file
   rm -rf $test2_mount/$test1_md5
   rm -rf $test2_mount/$test2_md5
if df | grep $test2_mount >/dev/null ;then
        umount $test2_mount
fi
if df | grep $test1_mount >/dev/null ;then
	umount $test1_mount
fi
mkdir $LSTRESULT/datatest
[ -f $LSTRESULT/datatest-error.log ] && mv $LSTRESULT/datatest-error.log $LSTRESULT/datatest
mv $LSTRESULT/datatest.log $LSTRESULT/datatest
rm -rf $tmpdir
}

#指定测试模式
prefile
dotest $2 $3 $4
