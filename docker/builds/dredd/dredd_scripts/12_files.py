import dredd_hooks as hooks
import imp
import os
import json
import requests
import uuid
import pprint
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Files
###############################################################################
###############################################################################
@hooks.before("Files > Files collection > Create file")
def all_but_filecreat12_1(transaction):
    global proj_id
    #create a project
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    proj_id = neww['id']
    #upload a file
    upload_id = utils.upload_a_file(proj_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['kind'] = 'dds-project'
    requestBody['parent']['id'] = proj_id
    requestBody['upload']['id'] = upload_id
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.after("Files > Files collection > Create file")
def grab_that_file_id12_1(transaction):
    global file_id
    json_trans = json.loads(transaction[u'real'][u'body'])
    file_id = json_trans['id']
    #print('This is my file id: ' + file_id)
@hooks.before("Files > File instance > View file")
def change_default_id12_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Files > File instance > Update file")
def change_defaultnew_id12_1(transaction):
    upload_id = utils.upload_a_file(proj_id,True)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['upload']['id'] = upload_id
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.before("Files > File instance > Delete file")
def del_new_file12_1(transaction):
    upload_id = utils.upload_a_file(proj_id,True)
    file_id = utils.create_a_file(proj_id,upload_id)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Files > File instance > Get file download URL")
def change_default_id212_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Files > File instance > Move file")
def move_id12_1(transaction):
    #create a project
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    folder_id = utils.create_a_folder(proj_id,'justaname')
    proj2_id = neww['id']
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['id'] = folder_id
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.before("Files > File instance > Rename file")
def just_renameit12_1(transaction):
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['name'] = 'somenewname.txt'
    transaction[u'request'][u'body'] = json.dumps(requestBody)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("File Versions > File Versions collection > List file versions")
def just_renameit212_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.after("File Versions > File Versions collection > List file versions")
def getting_those_versions12_1(transaction):
    global del_version_id, cur_version_id
    del_version_id = str(json.loads(transaction[u'real'][u'body'])[u'results'][0]['id'])
    cur_version_id = str(json.loads(transaction[u'real'][u'body'])[u'results'][1]['id'])
@hooks.before("File Versions > File Version instance > View file version")
@hooks.before("File Versions > File Version instance > Update file version")
@hooks.before("File Versions > File Version instance > Delete file version")
def view_this_version12_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b',del_version_id)
@hooks.before("File Versions > File Version instance > Get file version download URL")
def view_this_version212_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b',cur_version_id)
@hooks.before("File Versions > File Version instance > Promote file version")
# def skippy_z9(transaction):
#     utils.skip_this_endpoint(transaction)
def view_this_version212_12(transaction):
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    up_id = utils.upload_a_file(proj_id,unique=True)
    file_id = utils.create_a_file(proj_id,up_id)
    old_file_version = utils.get_current_file_version(file_id)
    up_id2 = utils.upload_a_file(proj_id,unique=True)
    new_file_version = utils.update_a_file(up_id2,file_id)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b',old_file_version)
