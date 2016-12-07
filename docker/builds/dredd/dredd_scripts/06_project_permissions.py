import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           PROJECT PERMISSIONS
###############################################################################
###############################################################################
@hooks.before("Project Permissions > Project Permissions collection > List project permissions")
def switch_url06_1(transaction):
    global this_project_id
    name = str(uuid.uuid4())
    description = "Created by dredd unders: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    url = transaction['fullPath']
    this_project_id = neww['id']
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id)
@hooks.before("Project Permissions > Project Permission instance > Grant project permission")
@hooks.before("Project Permissions > Project Permission instance > View project permission")
@hooks.before("Project Permissions > Project Permission instance > Revoke project permission")
def grant_it(transaction):
    notme = utils.get_user_id_notme()
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',notme)
