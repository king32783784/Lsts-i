#coding=utf8
import os,sys
import xml.dom.minidom
#from downloadfile import downLoadTestFile

class Parsing_XML():
    '''Parsing XML-formatted files for Lart_i'''

    def __init__(self,xml_file_name,Tagname='labelname'):
        self.xmlfile=xml_file_name
        self.Tagname=Tagname

    def parsing_label_list(self,labelname):
        '''Parsing Gets the list labels'''
        try:
            xml_dom=xml.dom.minidom.parse(self.xmlfile)
            xml_label=xml_dom.getElementsByTagName(labelname)
        except IOError:
            print 'Failed to open %s file,Please check it'%self.xmlfile
            exit(1)
        xml_label_list=[]
        for single_label in xml_label:
            xml_label_list.append(single_label.firstChild.data)
        return xml_label_list       

    def specific_elements(self):
        '''Read the specific elements,call the class may need to override this function
By default returns a "xml_list" and "xml_dict" a dictionary of xml_list specify a label for the list xml_dict key for the XML element, the corresponding value for a list of corresponding element tag content
        '''

        xml_labels=self.parsing_label_list(self.Tagname)
        xml_elements_dict={}
        for per_label in xml_labels:
            per_xml_label_list=self.parsing_label_list(per_label)
            xml_elements_dict[per_label]=per_xml_label_list
        xml_dict={'xml_list':xml_labels,'xml_dict':xml_elements_dict}
        return xml_dict


class Parsing_test_XML(Parsing_XML):
    ''' Parsing the test XMl files'''
    def __init__(self,xml_file_name):  
        self.xmlfile=xml_file_name

    def specific_elements(self,select_test_list):
        '''Parse each test parameter'''

        xml_test_Arguments_dict={}
        for per_label in select_test_list:
            per_xml_label_list=self.parsing_label_list(per_label)
            xml_test_Arguments_dict[per_label]=per_xml_label_list
        return xml_test_Arguments_dict



#setupxml=Parsing_XML('TestList.xml','Selecttype')
#testdir=setupxml.specific_elements()
#print testdir
#perftest=testdir['xml_dict']
#testlist=Parsing_test_XML('performance.xml')
#testarguments_list=testlist.specific_elements(perftest['performance'])
#print testarguments_list
