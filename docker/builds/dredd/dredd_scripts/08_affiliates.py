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
#           Affiliates
###############################################################################
###############################################################################
@hooks.before("Affiliates > Affiliates collection > List affiliates")
@hooks.before("Affiliates > Affiliate instance > Associate affiliate")
def affiliates_hooks08_1(transaction):
    global this_project_id, notme
    name = str(uuid.uuid4())
    description = "Created by dredd unders: Projects > Projects collection > Create project"
    neww = data_service.create_project(name,description)
    url = transaction['fullPath']
    this_project_id = str(json.loads(neww.text)['id'])
    users = data_service.get_users_by_page_and_offset(1,5)
    notme = str(json.loads(users.text)['results'][0]['id'])
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',notme)
@hooks.before("Affiliates > Affiliate instance > View affiliate")
@hooks.before("Affiliates > Affiliate instance > Delete affiliate")
def change_a_url(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1',this_project_id).replace('c1179f73-0558-4f96-afc7-9d251e65b7bb',notme)
