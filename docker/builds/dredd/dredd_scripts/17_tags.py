import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Tags
###############################################################################
###############################################################################
@hooks.before("Tags > Tags collection > Create object tag")
def create_tag17_1(transaction):
    global file_id
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(transaction,name,description)
    proj_id = neww['id']
    upload_id = utils.upload_a_file(proj_id,unique=True)
    file_id = utils.create_a_file(proj_id,upload_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['object']['id'] = file_id
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.after("Tags > Tags collection > Create object tag")
def get_tag_id(transaction):
    global tag_id
    requestBody = json.loads(transaction[u'real'][u'body'])
    tag_id = str(requestBody[u'id'])
    print(tag_id)
@hooks.before("Tags > Tags collection > List object tags")
def change_url12_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Tags > Tags collection > List tag labels")
def pass17_1(transaction):
    utils.pass_this_endpoint(transaction)
@hooks.before("Tags > Tag instance > View tag")
@hooks.before("Tags > Tag instance > Delete tag")
def change_url212_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('66211c4e-a49e-42d7-9793-87989d56e1e3',tag_id)
@hooks.before("Search Objects > NOT_IMPLEMENTED_NEW Search Objects > NOT_IMPLEMENTED_NEW Search Objects")
def skippy217_1(transaction):
    utils.skip_this_endpoint(transaction)
