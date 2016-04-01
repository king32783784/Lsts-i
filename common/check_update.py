import urllib2
import re

class Check_update():

    def __init__(self,target_url):
        self.url=target_url
    
    def get_htmlContent(self):
        try:
            html_Context=urllib2.urlopen(self.url).read()
            return unicode(html_Context,'utf-8')
        except IOError:
            print 'Failed to open xml file, please check it'
            exit(1)

    def return_checks(self):
        html_Context=get_htmlContent()
        return re.findall(r"href=(.+).iso\">",html_Context)

class Check_id(Check_update):

    def return_checks(self):
        html_Context=self.get_htmlContent()
        return  re.findall(r"<testid>(.+)</testid>",html_Context)[0]

#test=Check_id("http://192.168.32.18/Lsts-i/stability.xml")
#isoname=test.return_checks()
#print isoname
