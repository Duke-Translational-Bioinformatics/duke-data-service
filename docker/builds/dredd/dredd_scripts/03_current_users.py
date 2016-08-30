import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Current User
###############################################################################
############################################################################### 
@hooks.after("Current User > Current User instance > View current user")
def get_current_user_id03_1(transaction):
    global current_user_id
    current_user_id = json.loads(transaction[u'real'][u'body'])['id']
@hooks.before("Current User > Current User instance > Current user usage")
@hooks.before("Current User > Current User API Key > Generate current user API key")
@hooks.before("Current User > Current User API Key > View current user API key")
@hooks.before("Current User > Current User API Key > Delete current user API key")
@hooks.before("Users > Users collection > List users")
@hooks.before("Users > User instance > View user")
def view_user03_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',current_user_id) 
