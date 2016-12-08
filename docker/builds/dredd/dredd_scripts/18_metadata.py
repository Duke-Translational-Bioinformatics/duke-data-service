import dredd_hooks as hooks
import imp
import os
import json
import uuid
import re
import pprint
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Tags
###############################################################################
###############################################################################
@hooks.before("Metadata > Metadata Templates collection > Create metadata template")
def create_metadata_template(transaction):
    requestBody = json.loads(transaction[u'request'][u'body'])
    text = re.sub('\-','',str(uuid.uuid4()))
    requestBody['name'] = text
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.after("Metadata > Metadata Templates collection > Create metadata template")
def get_metadata_id(transaction):
    global metadata_id
    requestBody = json.loads(transaction[u'real'][u'body'])
    metadata_id = str(requestBody[u'id'])
    pprint.pprint(metadata_id)
@hooks.before("Metadata > Metadata Templates collection > List metadata templates")
def create_metadata_template_2(transaction):
    utils.pass_this_endpoint(transaction)
@hooks.before("Metadata > Metadata Template instance > View metadata template")
@hooks.before("Metadata > Metadata Template instance > Update metadata template")
@hooks.before("Metadata > Metadata Template instance > Delete metadata template")
def sub_metadata_id(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('168f3f51-6800-403a-973d-78b23c08049b',metadata_id)
@hooks.before("Metadata > Metadata Properties collection > Create metadata property")
def create_metadata_property(transaction):
    global metadata_id2
    metadata_id2 = utils.create_metadata_templatess()
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('168f3f51-6800-403a-973d-78b23c08049b',metadata_id2)
    requestBody = json.loads(transaction[u'request'][u'body'])
    text = re.sub('\-','',str(uuid.uuid4()))
    requestBody['key'] = text
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.after("Metadata > Metadata Properties collection > Create metadata property")
def get_that_id2(transaction):
    global metadata_key_id
    requestBody = json.loads(transaction[u'real'][u'body'])
    metadata_key_id = str(requestBody[u'id'])
@hooks.before("Metadata > Metadata Properties collection > List metadata properties")
def change_that_id(transaction):
    metadata_id3 = utils.create_metadata_templatess()
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('168f3f51-6800-403a-973d-78b23c08049b',metadata_id3)
@hooks.before("Metadata > Metadata Property instance > View metadata property")
@hooks.before("Metadata > Metadata Property instance > Update metadata property")
@hooks.before("Metadata > Metadata Property instance > Delete metadata property")
def change_that_id2za(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('48d34c8f-4284-4327-9ca6-7a9145a1c957',metadata_key_id)
@hooks.before("Metadata > Object Metadata instance > Create object metadata")
def create_file_and_object_z2s(transaction):
    global file_id, template_id
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = utils.create_a_project(name,description)
    proj_id = neww['id']
    upload_id = utils.upload_a_file(proj_id,True)
    file_id = utils.create_a_file(proj_id,upload_id)
    template_id = utils.create_metadata_templatess()
    metadata_property = utils.create_metadata_property(template_id)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('b80a2679-f6bf-46da-acaa-b7a4582b1eda',file_id).replace('168f3f51-6800-403a-973d-78b23c08049b',template_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['properties'][0]['key'] = utils.key
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.before("Metadata > Object Metadata instance > View object metadata")
def change_that_stuff12(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('b80a2679-f6bf-46da-acaa-b7a4582b1eda',file_id).replace('168f3f51-6800-403a-973d-78b23c08049b',template_id)
@hooks.before("Metadata > Object Metadata instance > Update object metadata")
def change_and_update234(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('b80a2679-f6bf-46da-acaa-b7a4582b1eda',file_id).replace('168f3f51-6800-403a-973d-78b23c08049b',template_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['properties'][0]['key'] = utils.key
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.before("Metadata > Object Metadata instance > Delete object metadata")
def change_that_stuff1ze2(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('b80a2679-f6bf-46da-acaa-b7a4582b1eda',file_id).replace('168f3f51-6800-403a-973d-78b23c08049b',template_id)
@hooks.before("Metadata > View All Object Metadata > View All Object Metadata")
def after_delete_view(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('b80a2679-f6bf-46da-acaa-b7a4582b1eda',file_id).replace('?meta_template_name=sequencing_file_info','')
    pprint.pprint(transaction['fullPath'])

# def skippy18_1(transaction):
#     utils.skip_this_endpoint(transaction)
