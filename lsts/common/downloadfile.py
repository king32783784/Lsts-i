import os
import urllib2
import urllib


class Download_File():
    ''' Download some files from the target server'''
    def __init__(self, target_url, file_name):
        self.url = target_url
        self.file = file_name

    def downloading(self):
        try:
            response = urllib2.urlopen(self.url)
            urllib.urlretrieve(self.url, self.file)
        except:
            print '\tError download the file:', self.url
            exit(1)

# test=Download_File('http://192.168.32.18/Lsts-i/','stability.xml')
# test.downloading()
