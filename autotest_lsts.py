#!/usr/bin/env python
#coding=utf8
'''
   function:Linux automated stability test
   Author:peng.li@i-soft.com.cn
   Time:20160401
'''
import os,sys,time,datetime
import threading
from common.parsing_xml import Parsing_XML
from common.initdaemon import Daemon
from common.check_update import Check_id
from common.downloadfile import Download_File

##解析配置文件，"test_setup_info"是个字典，其中'xml_list'对应配置列表；'xml_dict'是一个以配置项为键，其对应设置内容为值的字典" ##
test_setup=Parsing_XML('setup.xml','configlist')
global test_setup_info
test_setup_info=test_setup.specific_elements()
print test_setup_info

class Check_id_update(Daemon,Check_id,Download_File):

    def __init__(self,xmlurl,checkfrequency):
        Daemon.__init__(self)
        self.xmlurl=xmlurl[0]
        self.checkfrequency=checkfrequency[0]

    def _run(self):
        homedir = os.popen('pwd').read()
        local_xml_file=os.path.join(homedir,'/stability.xml')
        xml_url=os.path.join(self.xmlurl,'stability.xml')
        init_id=0
        while True:
            print self.xmlurl
            check_id=Check_id(xml_url)
            test_id=check_id.return_checks()
            if test_id > init_id:
                time.sleep(10)
                downxml=Download_File(self.xmlurl,local_xml_file)
                downxml.downloading()         
                init_id=test_id
            else:
                time.sleep(int(self.checkfrequency))


if __name__ == "__main__":
    daemon = Check_id_update(test_setup_info['xml_dict']['testitemurl'],test_setup_info['xml_dict']['checkfrequency'])
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
