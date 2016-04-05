import os
import linecache
import time
from common.parsing_xml import Parsing_XML


class ReadPublicinfo(Parsing_XML):
    def __init__(self):
        self.osname = self.os_name()
        self.setupinfo = self.setup_info()
        self.xmllocate = self.testxmllocate()

    def os_name(self):
        f = open('/etc/os-release', 'r')
        theline = linecache.getline("/etc/os-release", 5)
        osname_line = theline[13:-2]
        osname = osname_line.replace(' ', '_')
        return osname

    def setup_info(self):
        test_setup = Parsing_XML('setup.xml', 'configlist')
        test_setup_info = test_setup.specific_elements()
        return test_setup_info
     
    def testxmllocate(self):
        homedir = os.popen('pwd').read().strip('\n')
        local_xmlfile = os.path.join(homedir, 'tmp/stability.xml')
        return local_xmlfile

