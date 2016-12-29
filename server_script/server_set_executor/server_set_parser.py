#!/usr/bin/python

# AUTHOR : liuxu
# used to extract server sets from xml

import os
import sys
import getopt
from xml.dom.minidom import parse, parseString


#=======================================

class Server:
    
    def __init__(self, server_node):
        self.name = self.getXmlAttr(server_node, 'name')
        self.ip = self.getXmlAttr(server_node, 'ip')
        self.port = self.getXmlAttr(server_node, 'port')
        self.user = self.getXmlAttr(server_node, 'user')


    def getXmlAttr(self, node, attrname):
        return node.getAttribute(attrname) if node else ''


    def getAttr(self, attrname):
        return self.attrname


    def toString(self):
        print 'name=' + self.name + ',ip=' + self.ip + ',port=' + self.port + ',user=' + self.user


#=======================================


class ServerSet:
    
    def __init__(self, xml_node):
        self.name = self.getText(xml_node.getElementsByTagName('name')[0])

        active = self.getText(xml_node.getElementsByTagName('active')[0])
        if active == 'true':
            self.active = True
        else:
            self.active = False

        self.servers = []
        self.readServers(xml_node.getElementsByTagName('servers')[0])
        

    def getText(self, text_node):
        '''get text from xml node
        $text_node should be a node with type NODE_TEXT
        return str of the text
        '''
        ret = ''
        for n in text_node.childNodes:
            ret = ret + n.nodeValue
        return ret
        

    def readServers(self, servers_node):
        '''read servers and store them in self.servers
        $servers_node should be xml node with name of <servers>
        return none
        '''
        server_node_list = servers_node.getElementsByTagName('server')
        for n in server_node_list:
            server = Server(n)
            self.servers.append(server)

        
    def printServers(self):
        '''print all keywords in self.keywords
        return none
        '''
        for s in self.servers:
            s.toString()


    def printSummary(self):
        ser = ''
        count = len(self.servers)
        for i in range(count):
            ser = ser + self.servers[i].ip
            if i + 1 < count:
                ser = ser + ','
            if i >= 1:
                if i + 1 < count:
                    ser = ser + '...'
                break
        print self.name + ':[' + ser + '][' +  str(count) + ']'


    def toString(self):
        print 'name: ' + self.name
        print 'active: ' + str(self.active)
        print 'servers: '
        for s in self.servers:
            s.toString()
        

#=======================================


class ServerSetManager:

    def __init__(self, path):
        if not os.path.isfile(path):
            print '*. cannot find xml file: ' + path
            return
        
        self.path = path
        self.xml_doc = parse(self.path)
        self.xml_top = self.xml_doc.getElementsByTagName('ServerSetManager')[0]
        self.xml_set_list = self.xml_top.getElementsByTagName('server_set')
        self.set_list = []
        self.print_inactive = False

        for node in self.xml_set_list:
            #print self.getText(node.getElementsByTagName('name')[0])
            self.readServerSet(node)


    def getText(self, text_node):
        '''get text from xml node
        $text_node should be a node with type NODE_TEXT
        return str of the text
        '''
        r = ''
        for n in text_node.childNodes:
            r = r + n.nodeValue
        return r


    #param $node should be a 'keywordset' node in xml file
    def readServerSet(self, node):
        '''read server set and store them in self.set_list
        $node should be xml node twith name of <server_set>
        return none
        '''
        server_set = ServerSet(node)
        self.set_list.append(server_set)


    #param should be true or false
    def setPrintInactiveEnabled(self, inactive):
        '''set self.print_inactive
        '''
        self.print_inactive = inactive


    def listSets(self):
        for s in self.set_list:
            if s.active or self.print_inactive:
                s.printSummary()


    #param $set_name should be name of a server set
    def printSetBySetName(self, set_name):
        '''list servers in a server set by name
        if more than one server sets are with the same name, print them all
        '''
        for s in self.set_list:
            if s.name == set_name:
                if s.active or self.print_inactive:
                    s.printServers()


if __name__ == '__main__':
    opts, args = getopt.getopt(sys.argv[1:], 'f:lLn:')
    for op, value in opts:
        if op == '-f':
            manager = ServerSetManager(value)
        elif op == '-l':
            manager.listSets()
        elif op == '-n':
            manager.printSetBySetName(value)
        elif op == '-L':
            print '-----------------------------------'
            for s in manager.set_list:
                s.toString()
                print '-----------------------------------'
