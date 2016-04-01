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
from common.check_update import Check_update

##解析配置文件，"test_setup_info"是个字典，其中'xml_list'对应配置列表；'xml_dict'是一个以配置项为键，其对应设置内容为值的字典" ##
test_setup=Parsing_XML('setup.xml','configlist')
test_setup_info=test_setup.specific_elements()
print test_setup_info

class Time_check_update(threading.Thread,Check_update):

    def __init__(self,target_url):  
        threading.Thread.__init__(self) 
        self.url=target_url
    def run(self):
        print self.url
        now=datetime.datetime.now()
        get_isoname=Check_update()
        isoname=get_isoname.get_htmlContent(self.url)
        f=open('/home/test.log','w+')
        f.write("says hello world at %s"%now)
        f.write("%s"%isoname)
        time.sleep(3)


class Check_iso_update(Daemon):

    def __init__(self,isourl,checkfrequency):
       # super(Check_iso_update,self).__init__()
        Daemon.__init__(self)
        self.isourl=isourl
        self.checkfrequency=checkfrequency
    def _run(self):
        TestType="True"
        while TestType == "True":
            iso_update_thread=Time_check_update(self.isourl[0])
            iso_update_thread.start()
            TestTypea="False"
            time.sleep(int(self.checkfrequency[0]))



if __name__ == "__main__":
   # daemon = Check_iso_update(test_setup_info['xml_dict']['isourl'],test_setup_info['xml_dict']['checkfrequency'])
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
