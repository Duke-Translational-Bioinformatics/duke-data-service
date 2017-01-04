import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#         Children Search
###############################################################################
###############################################################################
@hooks.before("Search Children > Search project children > Search project children")
def justPass14_1(transaction):
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    proj_id = neww['id']
    upload_id = utils.upload_a_file(proj_id,True)
    file_id = utils.create_a_file(proj_id,upload_id)
    url = transaction['fullPath']
    temp = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',proj_id)
    temp = temp.split('?',1)[0]
    transaction['fullPath'] = temp
@hooks.before("Search Children > Search folder children > Search folder children")
def justPass214_1(transaction):
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    proj_id = neww ['id']
    upload_id = utils.upload_a_file(proj_id,True)
    file_id = utils.create_a_file(proj_id,upload_id)
    folder_id = utils.create_a_folder(proj_id,'justaname')
    url = transaction['fullPath']
    temp = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',folder_id)
    temp = temp.split('?',1)[0]
    transaction['fullPath'] = temp
