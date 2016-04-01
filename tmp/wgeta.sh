#!/bin/sh
wgetlog="$LSTRESULT/wgettest.log"
IP=$3
COUNTA=$2
time=$1
#启动服务端http服务
expect <<EOF
spawn ssh root@$IP     
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect  "]# "
send "sed -i 's/^/#/g' /etc/httpd/conf.d/welcome.conf\r"     
send "service httpd restart\r"
send "exit\r"
expect eof
exit
EOF
#生成测试文件
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

expect  <<EOF
set timeout -1
spawn scp bigfile root@$IP:/var/www/html/    
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect eof
spawn scp littlefile root@$IP:/var/www/html/
expect {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect eof
EOF

rm bigfile 
rm littlefile
[ -e $wgetlog ] && rm -f $wgetlog
dat=$(date +%s -d "$time hour")
while :
do
tim=$(date +%s)
if [ $tim -lt $dat ];then
    wget http://$IP/bigfile >/dev/null 2>&1
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Wget a large file failed \033[39;49;0m" | tee -a $wgetlog
    else
        echo -e "\033[33;49;1m Wget a large file successfully \033[39;49;0m" | tee -a $wgetlog
    fi
    MD5BIG1=`md5sum bigfile | awk '{print $1}'`
    MD5BIG2=`awk '{print $1}' bigfile.md5`
    if [ $MD5BIG2 = $MD5BIG1 ]; then
        echo -e "\033[33;49;1m  The large files verification successfully \033[39;49;0m" | tee -a $wgetlog
    else
        echo -e "\033[31;49;1m The large files verification failed \033[39;49;0m" | tee -a $wgetlog
    fi
       wget http://$IP/littlefile > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo -e "\033[31;49;1m Wget a little file failed \033[39;49;0m" | tee -a $wgetlog 
    else
        echo -e "\033[33;49;1m Wget a little file successfully \033[39;49;0m" | tee -a $wgetlog
    fi
    MD5BIG3=`md5sum littlefile | awk '{print $1}'`
    MD5BIG4=`awk '{print $1}' littlefile.md5`
    if [ $MD5BIG4 = $MD5BIG3 ]; then
        echo -e "\033[33;49;1m  The little files verification successfully \033[39;49;0m" | tee -a  $wgetlog
    else
        echo -e "\033[31;49;1m The little files verification failed \033[39;49;0m" | tee -a $wgetlog
    fi
    rm bigfile
    rm littlefile
else
break
fi
done


