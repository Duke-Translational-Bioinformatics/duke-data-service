import dredd_hooks as hooks
import imp
import os
import json
import hashlib
import requests
import uuid

from dataservice.config import create_config
from dataservice.core.fileuploader import FileUploadOperations, FileUploader, ParallelChunkProcessor
from dataservice.core.util import ProgressPrinter
from dataservice.core.localstore import LocalFile
from dataservice.core.ddsapi import DataServiceApi, DataServiceAuth
from dataservice.core.upload import ProjectUpload
config = create_config()
auth = DataServiceAuth(config)
data_service = DataServiceApi(auth, config.url)

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
    neww = data_service.create_project(name,description)
    url = transaction['fullPath']
    proj_id = str(json.loads(neww.text)['id'])
    transaction['fullPath'] = str(url).replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a',proj_id)
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
@hooks.before("Uploads > Upload instance > Complete chunked file upload")
def complete_this11_1(transaction):
    global upload_id
    progress_printer = ProgressPrinter(1, msg_verb='sending')
    name = str(uuid.uuid4())
    description = "Created by dredd under: Projects > Projects collection > Create project"
    neww = data_service.create_project(name,description)
    proj_id = str(json.loads(neww.text)['id'])
    local_file = LocalFile('made_up_data.Rdata')
    file_upload_object = FileUploader(config,data_service,local_file,progress_printer)
    upload_operations = FileUploadOperations(data_service)
    path_data = local_file.get_path_data()
    hash_data = path_data.get_hash()

    file_upload_object.upload_id = upload_operations.create_upload(proj_id,path_data,hash_data)
    upload_id = file_upload_object.upload_id
    with open('made_up_data.Rdata', 'rb') as infile:
        chunk = infile.read(config.upload_bytes_per_chunk)
    upload_url = upload_operations.create_file_chunk_url(file_upload_object.upload_id,1,chunk)
    upload_operations.send_file_external(upload_url,chunk)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id)
    upload_id2 = upload_id
@hooks.before("Uploads > Upload instance > Report upload hash")
def skippy11_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23',upload_id)
