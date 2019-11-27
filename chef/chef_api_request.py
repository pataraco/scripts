#!/usr/bin/env python
#
# requires
#   - pip install PyChef
#   - access to knife.rb file
#   - access to client.pem file
#
# DON'T RUN THIS - THESE ARE JUST EXAMPLES

#------------------------------
# update node info
from chef import autoconfigure, Node

api = autoconfigure()
n = Node('web1')
print n['fqdn']
n['myapp']['version'] = '1.0'
n.save()
#------------------------------

#------------------------------
# get client list
from chef import autoconfigure

api = autoconfigure()
print api.api_request('GET', '/clients')
#------------------------------
