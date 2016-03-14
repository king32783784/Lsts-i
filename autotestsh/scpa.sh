#!/bin/sh
scplog="$LSTRESULT/scptest.log"
IP=$3
COUNTA=$2
time=$1
[ -f bigfile ] && rm -rf bigfile
[ -f bigfile.md5sum ] && rm -rf bigfile.md5
[ -f littlefile ] && rm -rf littlefile
[ -f littlefile.md5sum ] && rm -rf littlefile.md5sum
echo -e "\033[32;49;1m  "Make test file start" \033[39;49;0m"
dd if=/dev/zero of=bigfile bs=1M count=$COUNTA  >/dev/null 2>&1                             #创建测试大文件
mkdir  littlefile
num=1
while [ "$num" -le $COUNTA ]; do                                                #创建测试小文件
    dd if=/dev/zero of=littlefile/$num bs=1k count=1024 >/dev/null 2>&1
    num=$(($num + 1))
done
echo 3 >/proc/sys/vm/drop_caches
tar cf littlefile.tar littlefile/
echo 3 >/proc/sys/vm/drop_caches
rm -rf littlefile
mv littlefile.tar littlefile
sync
md5sum bigfile > bigfile.md5
md5sum littlefile >littlefile.md5
expect <<EOF
set timeout -1
spawn scp bigfile root@$IP:/home/ 
expect {
 "yes/no" { send "yes\\r"; exp_continue}
 ":" { send "abc123\\r" }
}
expect eof
set timeout -1
spawn scp littlefile root@$IP:/home/ 
expect {
 "yes/no" { send "yes\\r"; exp_continue}
 ":" { send "abc123\\r" }
}
expect eof
EOF
rm littlefile
rm bigfile

[ -e $scplog ] && rm -f $scplog
dat=$(date +%s -d "$time hour")
while :
do
tim=$(date +%s)
if [ $tim -lt $dat ];then
expect -c "
set timeout -1
spawn scp -r root@$IP:/home/bigfile /home/
expect {
 "yes/no" { send "yes\\r"; exp_continue}
 ":" { send "abc123\\r" }
}
expect eof"
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Scp a large file failed \033[39;49;0m" | tee -a $scplog
    else
        echo -e "\033[33;49;1m Scp a large file successfully \033[39;49;0m" | tee -a $scplog
    fi
    MD5BIG1=`md5sum /home/bigfile | awk '{print $1}'`
    MD5BIG2=`awk '{print $1}' bigfile.md5`
    if [ $MD5BIG2 = $MD5BIG1 ]; then
        echo -e "\033[33;49;1m  The large files verification successfully \033[39;49;0m" | tee -a $scplog
    else
        echo -e "\033[31;49;1m The large files verification failed \033[39;49;0m" | tee -a $scplog
    fi
expect -c "
set timeout -1
spawn scp -r root@$IP:/home/littlefile /home/
expect {
 "yes/no" { send "yes\\r"; exp_continue}
 ":" { send "abc123\\r" }
}
expect eof"
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Scp a little file failed \033[39;49;0m" | tee -a $scplog
    else
        echo -e "\033[33;49;1m Scp a little file successfully \033[39;49;0m" | tee -a $scplog
    fi
    MD5BIG3=`md5sum /home/littlefile | awk '{print $1}'`
    MD5BIG4=`awk '{print $1}' littlefile.md5`
    if [ $MD5BIG4 = $MD5BIG3 ]; then
        echo -e "\033[33;49;1m  The little files verification successfully \033[39;49;0m" | tee -a $scplog
    else
        echo -e "\033[31;49;1m The little files verification failed \033[39;49;0m" | tee -a $scplog
    fi
    rm /home/bigfile
    rm /home/littlefile
else
break
fi
done

