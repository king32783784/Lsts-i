#!/usr/bin/env python
# coding=utf8
'''
   function:Linux automated stability test
   Author:peng.li@i-soft.com.cn
   Time:20160401
'''
import os
import sys
import time
import datetime
import threading
from common.parsing_xml import Parsing_XML
from common.initdaemon import Daemon
from common.check_update import CheckId
from common.downloadfile import Download_File
from public import ReadPublicinfo

# 解析配置文件，"test_setup_info"是个字典，其中'xml_list'对应配
# 置列表；'xml_dict'是一个以配置项为键，
# 其对应设置内容为值的字典" ##



class Check_id_Update(Daemon, CheckId, Download_File):

    def __init__(self, xmlurl, checkfrequency, loacl_xmlfile):
        Daemon.__init__(self)
        self.xmlurl = xmlurl[0]
        self.checkfrequency = checkfrequency[0]
        self.local_xmlfile = local_xmlfile

    def _run(self):
        init_id = 0
        while True:
            check_id = CheckId(self.xmlurl)
            test_id = check_id.return_checks()
            if test_id > init_id:
                time.sleep(10)
                downxml = Download_File(self.xmlurl, self.local_xmlfile)
                downxml.downloading()
               # testjob.runtest() 按照选中列表启动测试，并同时启动监控程序
                init_id = test_id
            else:
                time.sleep(int(self.checkfrequency))
     

if __name__ == "__main__":
    testxml = ReadPublicinfo()
    print testxml.setupinfo
    local_xmlfile = testxml.xmllocate
    daemon = Check_id_Update(testxml.setupinfo['xml_dict']['testitemurl'],
                             testxml.setupinfo['xml_dict']['checkfrequency'],
                             local_xmlfile)
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            daemon.start()
        elif 'stop' == sys.argv[1]:
            daemon.stop()
        elif 'restart' == sys.argv[1]:
            daemon.restart()
        else:
            print "unknown command"
            sys.exit(2)
        sys.exit(0)
    else:
        print "useage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)
