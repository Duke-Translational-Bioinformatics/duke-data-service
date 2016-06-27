import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Uploads
###############################################################################
###############################################################################
@hooks.before("Uploads > Uploads collection > Initiate chunked upload")
def change_an_id11_1(transaction):
    global proj_id
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(transaction,name,description)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',neww['id'])
    proj_id = neww['id']
@hooks.after("Uploads > Uploads collection > Initiate chunked upload")
def get_the_id11_1(transaction):
    global upload_id
    json_trans = json.loads(transaction[u'real'][u'body'])
    upload_id = json_trans['id']
@hooks.before("Uploads > Uploads collection > List chunked uploads")
def list_all_uploads(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',proj_id)
@hooks.before("Uploads > Upload instance > View chunked upload")
def list_upload_id11_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id)
@hooks.before("Uploads > Upload instance > Get pre-signed chunk URL")
@hooks.before("Uploads > Upload instance > Complete chunked file upload")
def skippy11_1(transaction):
    utils.pass_this_endpoint(transaction)
