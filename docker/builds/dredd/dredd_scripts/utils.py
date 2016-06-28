# -*- coding: utf-8 -*-
"""
Created on Wed Jun 15 15:07:15 2016

@author: nn31
"""

import requests
import os
import sys
import json
import hashlib

def skip_this_endpoint(transaction):
    transaction['skip'] = True

def pass_this_endpoint(transaction):
    pass

def create_a_project(transaction,name,description):
    url = os.getenv('HOST_NAME') + "/projects"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    body = { "name": name, "description": description}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    if r.status_code ==201:
        return(json.loads(r.text))
    else:
        raise ValueError('POST /projects returned: ' + str(r.status_code))

def create_a_sa(transaction,name):
    url = os.getenv('HOST_NAME') + "/software_agents"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    body = { "name": name}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    if r.status_code ==201:
        return(json.loads(r.text))
    else:
        raise ValueError('POST /software_agents returned: ' + str(r.status_code))

def generate_sa_key(transaction,_id):
    url = os.getenv('HOST_NAME') + "/software_agents/" + _id + "/api_key"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.put(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['key']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))

def generate_user_key(transaction):
    url = os.getenv('HOST_NAME') + "/current_user/api_key"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.put(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['key']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))

def get_user_id_notme(transaction):
    url = os.getenv('HOST_NAME') + "/users"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.get(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['results'][0]['id']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))

def upload_a_file(proj_id):
    #define everything that dds/swift will need
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
    ##Let data service know the upload is complete
    #if r3.status_code != 201:
    #    raise ValueError('Could not upload to swift, error ' + str(r3.status_code))
    url = os.getenv('HOST_NAME') + "/uploads/" + upload_id + "/complete"
    r4 = requests.put(url, headers=headers)
    ##Complete the process by creating a file
    body = {"parent":{"kind":"dds-project","id":proj_id},
            "upload":{"id":upload_id}}
    url = os.getenv('HOST_NAME') + "/files"
    r5 = requests.post(url, headers=headers, data=json.dumps(body))
    return_obj = {'upload_id':upload_id,
                  'file_id':str(json.loads(r5.text)['id'])}
    return(return_obj)
