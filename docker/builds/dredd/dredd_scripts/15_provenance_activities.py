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
    pprint.pprint(transaction.keys())
    pprint.pprint(transaction[u'real'])
@hooks.before("Provenance Activities > Activities collection > List activities")
@hooks.before("Provenance Activities > Activities instance > View activity")
@hooks.before("Provenance Activities > Activities instance > Update activity")
@hooks.before("Provenance Activities > Activities instance > Delete activity")
def justPass15_1(transaction):
    print(transaction['name'])
    utils.pass_this_endpoint(transaction)
