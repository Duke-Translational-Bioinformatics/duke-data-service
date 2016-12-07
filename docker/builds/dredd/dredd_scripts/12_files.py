import dredd_hooks as hooks
import imp
import os
import json
import requests
import uuid
import pprint

from dataservice.config import create_config
from dataservice.core.upload import ProjectUpload
from dataservice.core.util import ProgressPrinter
from dataservice.core.projectuploader import UploadSettings, ProjectUploader, UploadContext
from dataservice.core.fileuploader import FileUploader, FileUploadOperations
config = create_config()


utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Files
###############################################################################
###############################################################################
@hooks.before("Files > Files collection > Create file")
def all_but_filecreat12_1(transaction):
    global proj_id, upload_operations, data_service, hash_data, project_upload
    #create a project
    project_name = str(uuid.uuid4())
    # description = "Created by dredd under: Projects > Projects collection > Create project"
    # neww = data_service.create_project(name,description)
    # proj_id = str(json.loads(neww.text)['id'])
    #upload a file
    folders = ['made_up_data.Rdata']
    follow_symlinks=False
    project_upload = ProjectUpload(config, project_name, folders, follow_symlinks=follow_symlinks)
    neww = project_upload.remote_store.data_service.create_project(project_name,'test')
    proj_id = str(json.loads(neww.text)['id'])
    progress_printer = ProgressPrinter(project_upload.different_items.total_items(), msg_verb='sending')
    upload_settings = UploadSettings(project_upload.config, project_upload.remote_store.data_service, progress_printer,
                                     project_upload.project_name)
    upload_context = UploadContext(upload_settings, ())
    data_service = upload_context.make_data_service()
    upload_operations = FileUploadOperations(data_service)
    upload_id = upload_operations.create_upload(project_id=proj_id,
                                                path_data=project_upload.local_project.children[0].path_data,
                                                hash_data=project_upload.local_project.children[0].path_data.get_hash())
    url_data = upload_operations.create_file_chunk_url(upload_id,1,project_upload.local_project.children[0].path_data.read_whole_file())
    upload_operations.send_file_external(url_data,project_upload.local_project.children[0].path_data.read_whole_file())
    hash_data = project_upload.local_project.children[0].path_data.get_hash()
    data_service.complete_upload(upload_id, hash_data.value, hash_data.alg)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['parent']['kind'] = 'dds-project'
    requestBody['parent']['id'] = proj_id
    requestBody['upload']['id'] = str(upload_id)
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
    upload_id = upload_operations.create_upload(project_id=proj_id,
                                                path_data=project_upload.local_project.children[0].path_data,
                                                hash_data=project_upload.local_project.children[0].path_data.get_hash())
    url_data = upload_operations.create_file_chunk_url(upload_id,1,project_upload.local_project.children[0].path_data.read_whole_file())
    upload_operations.send_file_external(url_data,project_upload.local_project.children[0].path_data.read_whole_file())
    hash_data = project_upload.local_project.children[0].path_data.get_hash()
    data_service.complete_upload(upload_id, hash_data.value, hash_data.alg)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['upload']['id'] = upload_id
    transaction[u'request'][u'body'] = json.dumps(requestBody)
@hooks.before("Files > File instance > Delete file")
def del_new_file12_1(transaction):
    project_name = str(uuid.uuid4())
    folders = ['made_up_data.Rdata']
    follow_symlinks=False
    project_upload = ProjectUpload(config, project_name, folders, follow_symlinks=follow_symlinks)
    neww = project_upload.remote_store.data_service.create_project(project_name,'test')
    proj_id = str(json.loads(neww.text)['id'])
    progress_printer = ProgressPrinter(project_upload.different_items.total_items(), msg_verb='sending')
    upload_settings = UploadSettings(project_upload.config, project_upload.remote_store.data_service, progress_printer,
                                     project_upload.project_name)
    upload_context = UploadContext(upload_settings, ())
    data_service = upload_context.make_data_service()
    upload_operations = FileUploadOperations(data_service)
    upload_id = upload_operations.create_upload(project_id=proj_id,
                                                path_data=project_upload.local_project.children[0].path_data,
                                                hash_data=project_upload.local_project.children[0].path_data.get_hash())
    url_data = upload_operations.create_file_chunk_url(upload_id,1,project_upload.local_project.children[0].path_data.read_whole_file())
    upload_operations.send_file_external(url_data,project_upload.local_project.children[0].path_data.read_whole_file())
    hash_data = project_upload.local_project.children[0].path_data.get_hash()
    data_service.complete_upload(upload_id, hash_data.value, hash_data.alg)
    result = data_service.create_file('dds-project', proj_id, upload_id)
    file_id = str(result.json()['id'])
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Files > File instance > Get file download URL")
def change_default_id212_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('777be35a-98e0-4c2e-9a17-7bc009f9b111',file_id)
@hooks.before("Files > File instance > Move file")
def move_id12_1(transaction):
    #create a project
    xx = data_service.create_folder('test','dds-project',proj_id)
    folder_id = str(json.loads(xx.text)['id'])
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
def skippy_z9(transaction):
    utils.skip_this_endpoint(transaction)
# def view_this_version212_12(transaction):
#     name = str(uuid.uuid4())
#     description = "Created by dredd under: Projects > Projects collection > Create project"
#     up_id = utils.upload_a_file(proj_id,unique=True)
#     file_id = utils.create_a_file(proj_id,up_id)
#     old_file_version = utils.get_current_file_version(file_id)
#     up_id2 = utils.upload_a_file(proj_id,unique=True)
#     new_file_version = utils.update_a_file(up_id2,file_id)
#     url = transaction['fullPath']
#     transaction['fullPath'] = str(url).replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b',old_file_version)
