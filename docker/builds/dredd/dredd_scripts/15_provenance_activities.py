import dredd_hooks as hooks
import imp
import os
import json
import uuid
import pprint
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Provenance Activities
###############################################################################
###############################################################################
@hooks.before("Provenance Activities > Activities collection > Create activity")
def pass_this_a15_1(transaction):
    pass
@hooks.after("Provenance Activities > Activities collection > Create activity")
def get_prov_activity(transaction):
    global prov_id
    requestBody = json.loads(transaction[u'real'][u'body'])
    prov_id = requestBody[u'id']
@hooks.before("Provenance Activities > Activities collection > List activities")
def justPass15_1(transaction):
    utils.pass_this_endpoint(transaction)
@hooks.before("Provenance Activities > Activities instance > View activity")
@hooks.before("Provenance Activities > Activities instance > Update activity")
@hooks.before("Provenance Activities > Activities instance > Delete activity")
def changeid15_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('a1ff02a4-b7e9-999d-87x1-66f4c881jka1',prov_id)
