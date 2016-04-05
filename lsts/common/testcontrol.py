import os
import sys
import time
import datetime
import threading
from parsing_xml import Parsing_XML


class Parsing_test_XML(Parsing_XML):
    '''Parsing the test XML File'''
    def __init__(self, xml_file_name):
        self.xmlfile = xml_file_name

    def specific_elements(self, select_test_list):
        '''Parse each test parameter'''
        xml_test_Arguments_dict = {}
