import os

from parsing_xml import Parsing_XML


class JobControl(Parsing_XML):
    def __init__(self):
        self.testargs=self.parsingargs()

    def parsingargs(self,):
        checkxml = Parsing_XML('stbility.xml', 'stbtest')
        testxmlinfo = checkxml.specific_elements()
        return testxmlinfo

    def tooldownload(self):
        print self.testargs
