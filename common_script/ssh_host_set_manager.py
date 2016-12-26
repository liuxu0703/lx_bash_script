#!/usr/bin/python

# AUTHOR : liuxu-0703@163.com
# used to extract ssh hosts from xml

import os
import sys
import getopt
from xml.dom.minidom import parse, parseString

#=======================================

class Host:
    
    def __init__(self, xml_node):
        self.name = self.getText(xml_node.getElementsByTagName('name')[0])
        self.ip = self.getText(xml_node.getElementsByTagName('ip')[0])
        self.port = self.getText(xml_node.getElementsByTagName('port')[0])
        self.user = self.getText(xml_node.getElementsByTagName('user')[0])
        self.index = int(self.getText(xml_node.getElementsByTagName('index')[0]))
        active = self.getText(xml_node.getElementsByTagName('enabled')[0])
        try:
            self.password = self.getText(xml_node.getElementsByTagName('password')[0])
        except:
            self.password = ""
        if active == 'true':
            self.enabled = True
        else:
            self.enabled = False


    def getText(self, text_node):
        '''get text from xml node
        $text_node should be a node with type NODE_TEXT
        return str of the text
        '''
        ret = ''
        for n in text_node.childNodes:
            ret = ret + n.nodeValue
        return ret


    def printIp(self):
        print self.ip
        
    
    def printUser(self):
        print self.user
        
        
    def printPort(self):
        print self.port
        
        
    def printPassword(self):
        print self.password


    def printAllInfo(self):
        print 'name: ' + self.name
        print 'ip: ' + self.ip
        print 'port: ' + self.port
        print 'user: ' + self.user
        print 'password: ' + self.password
        print 'enabled: ' + str(self.enabled)
        print ' '


#=======================================


class HostManager:

    def __init__(self, path):
        if not os.path.isfile(path):
            print '*. cannot find xml file !'
            return
        
        self.path = path
        self.xml_doc = parse(self.path)
        self.xml_main = self.xml_doc.getElementsByTagName('SshHostmanager')[0]
        self.xml_host_list = self.xml_main.getElementsByTagName('host')
        self.host_list = []
        self.print_inactive = False

        for node in self.xml_host_list:
            self.readHost(node)

        self.host_list.sort(lambda x,y: self.compare(x, y))


    def compare(self, a, b):
        '''compare between two host instance
        $a and $b should be instance of host
        return -1, 0, 1
        '''
        return cmp(a.index, b.index)


    def readHost(self, node):
        '''read host from xml hode
        '''
        host = Host(node)
        self.host_list.append(host)


    #param should be true or false
    def setPrintInactiveEnabled(self, inactive):
        '''set self.print_inactive
        '''
        self.print_inactive = inactive


    def listHosts(self):
        '''print all host summary
        '''
        for host in self.host_list:
            if host.enabled or self.print_inactive:
                print host.name + '(' + host.ip + ')'
                
                
    def getHostByName(self, name):
        '''get host by name
        '''
        for host in self.host_list:
            if host.name == name:
                return host


    def printHostDetail(self, host_name):
        '''print a specified host detail
        '''
        for host in self.host_list:
            if host.name == host_name:
                if host.enabled or self.print_inactive:
                    host.printAllInfo()


if __name__ == '__main__':
    manager = HostManager(sys.path[0] + '/conf/ssh_host_set.xml')
    opts, args = getopt.getopt(sys.argv[1:], 'ldn:i:p:u:w:')
    
    for op, value in opts:
        if op == '-l':
            manager.listHosts()
        elif op == '-d':
            for host in km.host_list:
                host.printAllInfo()
        elif op == '-n':
            manager.printHostDetail(value)
        elif op == '-i':
            manager.getHostByName(value).printIp()
        elif op == '-p':
            manager.getHostByName(value).printPort()
        elif op == '-u':
            manager.getHostByName(value).printUser()
        elif op == '-w':
            manager.getHostByName(value).printPassword()
