import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Affiliates
###############################################################################
###############################################################################
@hooks.before("Affiliates > Affiliates collection > List affiliates")
@hooks.before("Affiliates > Affiliate instance > Associate affiliate")
def affiliates_hooks08_1(transaction):
    global this_project_id, notme
    name = str(uuid.uuid4())
    description = "Created by dredd unders: Projects > Projects collection > Create project"
    neww = utils.create_a_project(transaction,name,description)
    url = transaction['fullPath']
    this_project_id = str(neww['id'])
    notme = utils.get_user_id_notme(transaction)
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',notme)
@hooks.before("Affiliates > Affiliate instance > View affiliate")
@hooks.before("Affiliates > Affiliate instance > Delete affiliate")
def change_a_url(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',notme)
