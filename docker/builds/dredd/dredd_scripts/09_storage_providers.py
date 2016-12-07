import dredd_hooks as hooks
import imp
import os
import json
import uuid


###############################################################################
###############################################################################
#           Storage Providers
###############################################################################
###############################################################################
@hooks.after("Storage Providers > Storage Providers collection > List storage providers")
def get_storage_id(transaction):
    global storage_id
    json_trans = json.loads(transaction[u'real'][u'body'])
    storage_id = str(json_trans['results'][0]['id'])
@hooks.before("Storage Providers > Storage Provider instance > View storage provider")
def skippy09_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('g5579f73-0558-4f96-afc7-9d251e65bv33',storage_id)
