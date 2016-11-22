import dredd_hooks as hooks
import imp
import os
import json
import uuid

from dataservice.config import create_config
from dataservice.core.remotestore import RemoteStore, RemoteAuthRole
from dataservice.core.ddsapi import DataServiceApi, DataServiceError, DataServiceAuth
config = create_config()
auth = DataServiceAuth(config)
data_service = DataServiceApi(auth, config.url)


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
    neww = data_service.create_project(name,description)
    proj_id = str(json.loads(neww.text)['id'])
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['kind'] = 'dds-project'
    requestBody['parent']['id'] = proj_id
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
    neww = data_service.create_project(name,description)
    folder_id2 = data_service.create_folder('test','dds-project',str(json.loads(neww.text)['id']))
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',str(json.loads(folder_id2.text)['id']))
@hooks.before("Folders > Folder instance > Move folder")
def movin_this_folder(transaction):
    folder_id2 = data_service.create_folder('testers','dds-project',proj_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['id'] = str(json.loads(folder_id2.text)['id'])
    transaction[u'request'][u'body'] = json.dumps(requestBody)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id)
@hooks.before("Folders > Folder instance > Rename folder")
def viewin_my_folder210_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',folder_id)
