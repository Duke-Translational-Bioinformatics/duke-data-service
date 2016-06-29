import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Folders
###############################################################################
###############################################################################
@hooks.before("Folders > Folders collection > Create folder")
def create_folder10_1(transaction):
    global proj_id
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(transaction,name,description)
    proj_id = neww['id']
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['kind'] = 'dds-project'
    requestBody['parent']['id'] = neww['id']
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.after("Folders > Folders collection > Create folder")
def gettin_my_folder_id10_1(transaction):
    global folder_id
    requestBody = json.loads(transaction[u'real'][u'body'])
    folder_id = str(requestBody[u'id'])
@hooks.before("Folders > Folder instance > View folder")
def viewin_my_folder10_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id)
@hooks.before("Folders > Folder instance > Delete folder")
def create_and_tear_down10_1(transaction):
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(transaction,name,description)
    folder_id2 = utils.create_a_folder(neww['id'],'test')
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id2)
@hooks.before("Folders > Folder instance > Move folder")
def movin_this_folder(transaction):
    folder_id2 = utils.create_a_folder(proj_id,'test')
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['id'] = folder_id2
    transaction[u'request'][u'body'] = json.dumps(requestBody)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id)
@hooks.before("Folders > Folder instance > Rename folder")
def viewin_my_folder210_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id)
