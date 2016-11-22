import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
from dataservice.config import create_config
from dataservice.core.remotestore import RemoteStore, RemoteAuthRole
from dataservice.core.ddsapi import DataServiceApi, DataServiceError, DataServiceAuth
config = create_config()
auth = DataServiceAuth(config)
data_service = DataServiceApi(auth, config.url)

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
    neww = data_service.create_project(name,description)
    url = transaction['fullPath']
    this_project_id = str(json.loads(neww.text)['id'])
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id)
@hooks.before("Project Permissions > Project Permission instance > Grant project permission")
@hooks.before("Project Permissions > Project Permission instance > View project permission")
@hooks.before("Project Permissions > Project Permission instance > Revoke project permission")
def grant_it(transaction):
    users = data_service.get_users_by_page_and_offset(1,5)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',str(json.loads(users.text)['results'][0]['id']))
