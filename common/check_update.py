
import urllib2
import re

class Check_update():

    def get_htmlContent(self,target_url):
        html_Context=urllib2.urlopen(target_url).read()
        html_Context=unicode(html_Context,'utf-8')
        return re.findall(r"href=(.+).iso\">",html_Context)
        
#test=Check_update()
#isoname=test.get_htmlContent(http://192.168.32.18/iso/")
#print isoname
