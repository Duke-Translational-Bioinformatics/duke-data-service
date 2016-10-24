import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Authorization Roles
###############################################################################
###############################################################################
@hooks.before("Authorization Roles > Authorization Roles collection > List roles")
def justPass01_1(transaction):
    print('test')
    utils.pass_this_endpoint(transaction)
@hooks.before("Authorization Roles > Authorization Role instance > View role")
def justPass01_2(transaction):
    utils.pass_this_endpoint(transaction)
