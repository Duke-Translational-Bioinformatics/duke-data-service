import dredd_hooks as hooks
import imp
import os
import json
import hashlib
import requests
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
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',neww['id'])
    proj_id = neww['id']
    print(proj_id)
@hooks.after("Uploads > Uploads collection > Initiate chunked upload")
def get_the_id11_1(transaction):
    global upload_id
    json_trans = json.loads(transaction[u'real'][u'body'])
    upload_id = json_trans['id']
@hooks.before("Uploads > Uploads collection > List chunked uploads")
def list_all_uploads(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',proj_id)
@hooks.before("Uploads > Upload instance > View chunked upload")
@hooks.before("Uploads > Upload instance > Get pre-signed chunk URL")
def list_upload_id11_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id)
@hooks.before("Uploads > Upload instance > NOT_IMPLEMENTED_CHANGE Complete chunked file upload")
def complete_this11_1(transaction):
    global upload_id2
    chunk = {};
    chunk['content'] = 'This is sample chunk content for chunk number: \n';
    chunk['content_type'] = 'text/plain';
    chunk['number'] = 1;
    chunk['size'] = len(chunk['content'])
    chunk['hash'] = {};
    chunk['hash']['value'] = hashlib.md5(chunk['content']).hexdigest();
    chunk['hash']['algorithm'] = 'md5';
    #first we'll initiate the upload process
    body = {"name": "made_up_data.Rdata",
            "content_type": chunk['content_type'],
            "size": chunk['size'],
            "hash": {"value":chunk['hash']['value'],"algorithm":'md5'}
            }
    url = os.getenv('HOST_NAME') + "/projects/" + proj_id + "/uploads"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    #if r.status_code != 201:
    #    raise ValueError("upload_a_file could not initiate the chunked upload error: " + str(r.status_code))
    upload_id = str(json.loads(r.text)['id'])
    ## Now we need to get a pre-signed url to the swift storage facility
    body = {"number": 1,
            "size": chunk['size'],
            "hash": {"value":chunk['hash']['value'],"algorithm":'md5'}
            }
    url = os.getenv('HOST_NAME') + "/uploads/" + upload_id + "/chunks"
    r2 = requests.put(url, headers=headers, data=json.dumps(body))
    ## Now we need to upload the document
    body = chunk['content']
    url = str(json.loads(r2.text)['host']) + str(json.loads(r2.text)['url'])
    r3 = requests.put(url, headers=headers, data=body)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id)
    upload_id2 = upload_id
@hooks.before("Uploads > Upload instance > Report upload hash")
def skippy11_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id2)
