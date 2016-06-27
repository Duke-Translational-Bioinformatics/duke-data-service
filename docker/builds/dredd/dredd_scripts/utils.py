# -*- coding: utf-8 -*-
"""
Created on Wed Jun 15 15:07:15 2016

@author: nn31
"""

import requests
import os
import json

def skip_this_endpoint(transaction):
    transaction['skip'] = True
    
def pass_this_endpoint(transaction):
    pass

def create_a_project(transaction,name,description):
    url = "http://192.168.99.100:3001/api/v1/projects"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    body = { "name": name, "description": description}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    if r.status_code ==201:
        return(json.loads(r.text))
    else:
        raise ValueError('POST /projects returned: ' + str(r.status_code))
        
def create_a_sa(transaction,name):
    url = "http://192.168.99.100:3001/api/v1/software_agents"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    body = { "name": name}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    if r.status_code ==201:
        return(json.loads(r.text))
    else:
        raise ValueError('POST /software_agents returned: ' + str(r.status_code))
    
def generate_sa_key(transaction,_id):
    url = "http://192.168.99.100:3001/api/v1/software_agents/" + _id + "/api_key"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.put(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['key']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))
        
def generate_user_key(transaction):
    url = "http://192.168.99.100:3001/api/v1/current_user/api_key"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.put(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['key']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))
        
def get_user_id_notme(transaction):
    url = "http://192.168.99.100:3001/api/v1/users"
    headers = { "Content-Type": "application/json", "Authorization": os.getenv('MY_GENERATED_JWT')}
    r = requests.get(url, headers=headers)
    if r.status_code ==200:
        text = json.loads(r.text)
        return(str(text['results'][0]['id']))
    else:
        raise ValueError('PUT /software_agents returned: ' + str(r.status_code))
        