#!/bin/sh
tftplog="$LSTRESULT/tftptest.log"
IP=$3
COUNTA=$1
time=$2
#配置另一台做tftp服务器
expect  <<EOF 
spawn ssh root@$IP  
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect  "#"
send "yum install tftp\r"
send "yum install tftp-server\r"
send "sed -i '12,20s/yes/no/' /etc/xinetd.d/tftp\r"
send "service iptables stop\r"
send "setenforce 0\r"
send "service xinetd restart\r"
send "exit\r"
expect eof
exit
EOF

#生成测试文件，并发送到另一台机器
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
md5sum littlefile > littlefile.md5

expect  <<EOF
set timeout -1
spawn scp bigfile root@$IP:/var/lib/tftpboot     
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect eof
spawn scp littlefile root@$IP:/var/lib/tftpboot     
expect  {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "abc123\r" }
}
expect eof
EOF
rm littlefile
rm bigfile

[ -e $tftplog ] && rm -f $tftplog

dat=`date +%s -d "$time hour"`
while :
do
tim=`date +%s`
if [ $tim -lt $dat ];then
    expect <<EOF
    set timeout -1
    spawn tftp $IP
    expect tftp> 
    send "get bigfile /home/bigfile\r"
    send "q\r"
    expect eof
EOF
    MD5BIG1=`md5sum /home/bigfile | awk '{print $1}'`
    MD5BIG2=`awk '{print $1}' bigfile.md5`
    if [ $MD5BIG2 = $MD5BIG1 ]; then
        echo -e "\033[33;49;1m  The large files verification successfully \033[39;49;0m" >>$tftplog
  else
        echo -e "\033[31;49;1m The large files verification failed \033[39;49;0m" >>$tftplog
    fi
   expect   <<EOF
    set timeout -1
    spawn tftp $IP
    expect "tftp> "
    send "get littlefile /home/littlefile\r"
    send "q\r"
    expect eof
EOF
    MD5BIG3=`md5sum /home/bigfile | awk '{print $1}'`
    MD5BIG4=`awk '{print $1}' bigfile.md5`
    if [ $MD5BIG4 = $MD5BIG3 ]; then
        echo -e "\033[33;49;1m  The large files verification successfully \033[39;49;0m" >>$tftplog
  else
        echo -e "\033[31;49;1m The large files verification failed \033[39;49;0m" >>$tftplog
    fi

    rm /home/bigfile
    rm /home/littlefile
else
break
fi
done

